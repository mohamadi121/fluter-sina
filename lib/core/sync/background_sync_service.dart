import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import '../database/offline_database.dart';
import '../network/enhanced_http_client.dart';
import '../firebase/firebase_manager.dart';
import '../../features/auth/services/security_service.dart';

/// Background Sync Service for offline data synchronization
class BackgroundSyncService {
  static final BackgroundSyncService _instance = BackgroundSyncService._internal();
  factory BackgroundSyncService() => _instance;
  BackgroundSyncService._internal();

  final OfflineDatabase _database = OfflineDatabase();
  final EnhancedHttpClient _httpClient = EnhancedHttpClient();
  final SecurityService _security = SecurityService();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _periodicSyncTimer;
  bool _isSyncing = false;
  bool _isInitialized = false;

  // Configuration
  static const String _backgroundTaskName = 'background_sync_task';
  static const Duration _syncInterval = Duration(minutes: 15);
  static const Duration _immediateRetryDelay = Duration(seconds: 30);
  static const int _maxRetryAttempts = 3;
  static const int _batchSize = 10;

  // Conflict resolution strategies
  static const String _conflictResolutionServerWins = 'server_wins';
  static const String _conflictResolutionClientWins = 'client_wins';
  static const String _conflictResolutionMerge = 'merge';
  static const String _conflictResolutionManual = 'manual';

  /// Initialize background sync service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize dependencies
      await _database.initialize();
      
      // Setup connectivity monitoring
      _setupConnectivityMonitoring();
      
      // Setup periodic sync
      _setupPeriodicSync();
      
      // Initialize background tasks
      await _initializeBackgroundTasks();
      
      _isInitialized = true;

      await _security.logSecurityEvent(
        SecurityEventType.authSuccess,
        'Background sync service initialized',
      );

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Background sync initialization failed');
      rethrow;
    }
  }

  /// Setup connectivity monitoring
  void _setupConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final isConnected = results.contains(ConnectivityResult.mobile) || 
                           results.contains(ConnectivityResult.wifi);
        
        if (isConnected && !_isSyncing) {
          // Start immediate sync when connectivity is restored
          _startImmediateSync();
        }
      },
    );
  }

  /// Setup periodic sync timer
  void _setupPeriodicSync() {
    _periodicSyncTimer = Timer.periodic(_syncInterval, (timer) {
      if (!_isSyncing) {
        _performPeriodicSync();
      }
    });
  }

  /// Initialize background tasks
  Future<void> _initializeBackgroundTasks() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode,
      );

      // Register periodic background sync
      await Workmanager().registerPeriodicTask(
        _backgroundTaskName,
        _backgroundTaskName,
        frequency: const Duration(hours: 1),
        constraints: Constraints(
          networkType: NetworkType.connected,
          requiresBatteryNotLow: true,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: true,
        ),
      );

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Background task initialization failed');
    }
  }

  /// Start immediate sync
  Future<void> _startImmediateSync() async {
    try {
      await Future.delayed(_immediateRetryDelay);
      await performSync();
    } catch (e) {
      debugPrint('[BackgroundSync] Immediate sync failed: $e');
    }
  }

  /// Perform periodic sync
  Future<void> _performPeriodicSync() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final isConnected = connectivity.contains(ConnectivityResult.mobile) || 
                         connectivity.contains(ConnectivityResult.wifi);
      
      if (isConnected) {
        await performSync();
      }
    } catch (e) {
      debugPrint('[BackgroundSync] Periodic sync failed: $e');
    }
  }

  /// Perform complete synchronization
  Future<SyncResult> performSync({bool forceful = false}) async {
    if (_isSyncing && !forceful) {
      return SyncResult.skipped('Sync already in progress');
    }

    _isSyncing = true;
    final startTime = DateTime.now();

    try {
      await _security.logSecurityEvent(
        SecurityEventType.authSuccess,
        'Background sync started',
        metadata: {
          'forceful': forceful,
          'start_time': startTime.millisecondsSinceEpoch,
        },
      );

      // Check connectivity
      final connectivity = await Connectivity().checkConnectivity();
      final isConnected = connectivity.contains(ConnectivityResult.mobile) || 
                         connectivity.contains(ConnectivityResult.wifi);
      
      if (!isConnected) {
        return SyncResult.failed('No internet connection');
      }

      // Get pending sync items
      final pendingItems = await _database.getPendingSyncItems(limit: _batchSize * 2);
      
      if (pendingItems.isEmpty) {
        return SyncResult.success('No items to sync', 0, 0);
      }

      int successCount = 0;
      int failureCount = 0;
      final conflicts = <Map<String, dynamic>>[];

      // Process sync items in batches
      for (int i = 0; i < pendingItems.length; i += _batchSize) {
        final batch = pendingItems.skip(i).take(_batchSize).toList();
        
        for (final item in batch) {
          try {
            final result = await _processSyncItem(item);
            
            if (result.isSuccess) {
              await _database.markSyncCompleted(item['id']);
              successCount++;
            } else if (result.isConflict) {
              conflicts.add(item);
              await _handleSyncConflict(item, result);
            } else {
              await _database.markSyncFailed(item['id'], error: result.error);
              failureCount++;
            }
          } catch (e) {
            await _database.markSyncFailed(item['id'], error: e.toString());
            failureCount++;
          }
        }

        // Small delay between batches to avoid overwhelming the server
        if (i + _batchSize < pendingItems.length) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      // Handle conflicts
      if (conflicts.isNotEmpty) {
        await _processConflicts(conflicts);
      }

      final duration = DateTime.now().difference(startTime);

      await _security.logSecurityEvent(
        SecurityEventType.authSuccess,
        'Background sync completed',
        metadata: {
          'duration_ms': duration.inMilliseconds,
          'success_count': successCount,
          'failure_count': failureCount,
          'conflict_count': conflicts.length,
        },
      );

      return SyncResult.success(
        'Sync completed successfully',
        successCount,
        failureCount,
        conflicts.length,
      );

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Background sync failed');
      
      await _security.logSecurityEvent(
        SecurityEventType.suspiciousActivity,
        'Background sync error',
        metadata: {
          'error': e.toString(),
          'duration_ms': DateTime.now().difference(startTime).inMilliseconds,
        },
      );

      return SyncResult.failed('Sync failed: ${e.toString()}');
    } finally {
      _isSyncing = false;
    }
  }

  /// Process individual sync item
  Future<SyncItemResult> _processSyncItem(Map<String, dynamic> item) async {
    try {
      final tableName = item['table_name'] as String;
      final recordId = item['record_id'] as String;
      final operation = item['operation'] as String;
      final data = jsonDecode(item['data'] as String) as Map<String, dynamic>;

      switch (tableName) {
        case 'devices':
          return await _syncDevice(recordId, operation, data);
        case 'energy_data':
          return await _syncEnergyData(recordId, operation, data);
        default:
          return SyncItemResult.failed('Unknown table: $tableName');
      }
    } catch (e) {
      return SyncItemResult.failed('Processing failed: ${e.toString()}');
    }
  }

  /// Sync device data
  Future<SyncItemResult> _syncDevice(
    String deviceId,
    String operation,
    Map<String, dynamic> data,
  ) async {
    try {
      switch (operation) {
        case 'insert':
          final response = await _httpClient.post('/devices', data: data);
          if (response.statusCode == 201) {
            return SyncItemResult.success();
          } else if (response.statusCode == 409) {
            return SyncItemResult.conflict(response.data);
          } else {
            return SyncItemResult.failed('Server error: ${response.statusCode}');
          }

        case 'update':
          final response = await _httpClient.put('/devices/$deviceId', data: data);
          if (response.statusCode == 200) {
            return SyncItemResult.success();
          } else if (response.statusCode == 409) {
            return SyncItemResult.conflict(response.data);
          } else if (response.statusCode == 404) {
            // Device doesn't exist on server, create it
            return await _syncDevice(deviceId, 'insert', data);
          } else {
            return SyncItemResult.failed('Server error: ${response.statusCode}');
          }

        case 'delete':
          final response = await _httpClient.delete('/devices/$deviceId');
          if (response.statusCode == 200 || response.statusCode == 404) {
            return SyncItemResult.success();
          } else {
            return SyncItemResult.failed('Server error: ${response.statusCode}');
          }

        default:
          return SyncItemResult.failed('Unknown operation: $operation');
      }
    } catch (e) {
      return SyncItemResult.failed('Network error: ${e.toString()}');
    }
  }

  /// Sync energy data
  Future<SyncItemResult> _syncEnergyData(
    String dataId,
    String operation,
    Map<String, dynamic> data,
  ) async {
    try {
      switch (operation) {
        case 'insert':
          final response = await _httpClient.post('/energy-data', data: data);
          if (response.statusCode == 201) {
            return SyncItemResult.success();
          } else if (response.statusCode == 409) {
            return SyncItemResult.conflict(response.data);
          } else {
            return SyncItemResult.failed('Server error: ${response.statusCode}');
          }

        case 'update':
          final response = await _httpClient.put('/energy-data/$dataId', data: data);
          if (response.statusCode == 200) {
            return SyncItemResult.success();
          } else if (response.statusCode == 409) {
            return SyncItemResult.conflict(response.data);
          } else if (response.statusCode == 404) {
            // Data doesn't exist on server, create it
            return await _syncEnergyData(dataId, 'insert', data);
          } else {
            return SyncItemResult.failed('Server error: ${response.statusCode}');
          }

        case 'delete':
          final response = await _httpClient.delete('/energy-data/$dataId');
          if (response.statusCode == 200 || response.statusCode == 404) {
            return SyncItemResult.success();
          } else {
            return SyncItemResult.failed('Server error: ${response.statusCode}');
          }

        default:
          return SyncItemResult.failed('Unknown operation: $operation');
      }
    } catch (e) {
      return SyncItemResult.failed('Network error: ${e.toString()}');
    }
  }

  /// Handle sync conflict
  Future<void> _handleSyncConflict(
    Map<String, dynamic> syncItem,
    SyncItemResult result,
  ) async {
    try {
      final localData = jsonDecode(syncItem['data'] as String) as Map<String, dynamic>;
      final serverData = result.serverData ?? {};

      await _database.addConflict(
        tableName: syncItem['table_name'],
        recordId: syncItem['record_id'],
        localData: localData,
        serverData: serverData,
        conflictType: _determineConflictType(localData, serverData),
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Handle sync conflict failed');
    }
  }

  /// Determine conflict type
  String _determineConflictType(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
  ) {
    final localVersion = localData['version'] as int? ?? 0;
    final serverVersion = serverData['version'] as int? ?? 0;
    final localTimestamp = localData['updated_at'] as int? ?? 0;
    final serverTimestamp = serverData['updated_at'] as int? ?? 0;

    if (localVersion > serverVersion) {
      return 'local_newer';
    } else if (serverVersion > localVersion) {
      return 'server_newer';
    } else if (localTimestamp > serverTimestamp) {
      return 'local_more_recent';
    } else if (serverTimestamp > localTimestamp) {
      return 'server_more_recent';
    } else {
      return 'concurrent_modification';
    }
  }

  /// Process conflicts using automatic resolution strategies
  Future<void> _processConflicts(List<Map<String, dynamic>> conflicts) async {
    for (final conflict in conflicts) {
      try {
        final resolutionStrategy = await _getConflictResolutionStrategy(conflict);
        
        if (resolutionStrategy != _conflictResolutionManual) {
          await _autoResolveConflict(conflict, resolutionStrategy);
        }
      } catch (e) {
        FirebaseManager().logError(e, StackTrace.current, reason: 'Process conflict failed');
      }
    }
  }

  /// Get conflict resolution strategy
  Future<String> _getConflictResolutionStrategy(Map<String, dynamic> conflict) async {
    // Get user preferences from metadata
    final userStrategy = await _database.getMetadata('conflict_resolution_strategy');
    
    if (userStrategy != null) {
      return userStrategy;
    }

    // Default strategy based on conflict type
    final tableName = conflict['table_name'] as String;
    
    switch (tableName) {
      case 'devices':
        return _conflictResolutionServerWins; // Server wins for device status
      case 'energy_data':
        return _conflictResolutionMerge; // Merge energy data
      default:
        return _conflictResolutionManual; // Manual resolution for unknown types
    }
  }

  /// Auto-resolve conflict
  Future<void> _autoResolveConflict(
    Map<String, dynamic> conflict,
    String strategy,
  ) async {
    try {
      final localData = jsonDecode(conflict['local_data'] as String) as Map<String, dynamic>;
      final serverData = jsonDecode(conflict['server_data'] as String) as Map<String, dynamic>;
      
      Map<String, dynamic> resolvedData;

      switch (strategy) {
        case _conflictResolutionServerWins:
          resolvedData = serverData;
          break;
        case _conflictResolutionClientWins:
          resolvedData = localData;
          break;
        case _conflictResolutionMerge:
          resolvedData = _mergeConflictData(localData, serverData);
          break;
        default:
          return; // Manual resolution required
      }

      await _database.resolveConflict(
        conflict['id'],
        strategy,
        resolvedData,
      );

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Auto-resolve conflict failed');
    }
  }

  /// Merge conflict data
  Map<String, dynamic> _mergeConflictData(
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
  ) {
    final merged = Map<String, dynamic>.from(serverData);
    
    // Merge strategy: keep server data but preserve local timestamps for certain fields
    final preserveLocalFields = ['battery_level', 'energy_usage'];
    
    for (final field in preserveLocalFields) {
      if (localData.containsKey(field)) {
        final localTimestamp = localData['updated_at'] as int? ?? 0;
        final serverTimestamp = serverData['updated_at'] as int? ?? 0;
        
        if (localTimestamp > serverTimestamp) {
          merged[field] = localData[field];
        }
      }
    }
    
    merged['updated_at'] = DateTime.now().millisecondsSinceEpoch;
    merged['version'] = (math.max(
      localData['version'] as int? ?? 0,
      serverData['version'] as int? ?? 0,
    )) + 1;
    
    return merged;
  }

  /// Force immediate sync
  Future<SyncResult> forceSync() async {
    return await performSync(forceful: true);
  }

  /// Get sync status
  Future<SyncStatus> getSyncStatus() async {
    try {
      final stats = await _database.getDatabaseStats();
      final lastSyncTime = await _database.getMetadata('last_sync_time');
      
      return SyncStatus(
        isActive: _isSyncing,
        pendingCount: stats['pending_sync_count'] ?? 0,
        conflictCount: stats['conflict_count'] ?? 0,
        lastSyncTime: lastSyncTime != null 
          ? DateTime.fromMillisecondsSinceEpoch(int.parse(lastSyncTime))
          : null,
      );
    } catch (e) {
      return SyncStatus(
        isActive: false,
        pendingCount: 0,
        conflictCount: 0,
        lastSyncTime: null,
      );
    }
  }

  /// Set conflict resolution strategy
  Future<void> setConflictResolutionStrategy(String strategy) async {
    await _database.setMetadata('conflict_resolution_strategy', strategy);
  }

  /// Get unresolved conflicts for manual resolution
  Future<List<ConflictInfo>> getUnresolvedConflicts() async {
    try {
      final conflicts = await _database.getUnresolvedConflicts();
      
      return conflicts.map((conflict) => ConflictInfo(
        id: conflict['id'],
        tableName: conflict['table_name'],
        recordId: conflict['record_id'],
        localData: jsonDecode(conflict['local_data']),
        serverData: jsonDecode(conflict['server_data']),
        conflictType: conflict['conflict_type'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(conflict['created_at']),
      )).toList();
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Get unresolved conflicts failed');
      return [];
    }
  }

  /// Manually resolve conflict
  Future<void> manuallyResolveConflict(
    int conflictId,
    Map<String, dynamic> resolvedData,
  ) async {
    await _database.resolveConflict(
      conflictId,
      _conflictResolutionManual,
      resolvedData,
    );
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _periodicSyncTimer?.cancel();
  }
}

/// Background task callback dispatcher
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final syncService = BackgroundSyncService();
      await syncService.initialize();
      
      final result = await syncService.performSync();
      
      return result.isSuccess;
    } catch (e) {
      debugPrint('[BackgroundSync] Background task failed: $e');
      return false;
    }
  });
}

/// Sync result data class
class SyncResult {
  final bool isSuccess;
  final String message;
  final int successCount;
  final int failureCount;
  final int conflictCount;

  SyncResult._({
    required this.isSuccess,
    required this.message,
    this.successCount = 0,
    this.failureCount = 0,
    this.conflictCount = 0,
  });

  factory SyncResult.success(
    String message,
    int successCount,
    int failureCount, [
    int conflictCount = 0,
  ]) {
    return SyncResult._(
      isSuccess: true,
      message: message,
      successCount: successCount,
      failureCount: failureCount,
      conflictCount: conflictCount,
    );
  }

  factory SyncResult.failed(String message) {
    return SyncResult._(
      isSuccess: false,
      message: message,
    );
  }

  factory SyncResult.skipped(String message) {
    return SyncResult._(
      isSuccess: true,
      message: message,
    );
  }
}

/// Sync item result
class SyncItemResult {
  final bool isSuccess;
  final bool isConflict;
  final String? error;
  final Map<String, dynamic>? serverData;

  SyncItemResult._({
    required this.isSuccess,
    required this.isConflict,
    this.error,
    this.serverData,
  });

  factory SyncItemResult.success() {
    return SyncItemResult._(isSuccess: true, isConflict: false);
  }

  factory SyncItemResult.failed(String error) {
    return SyncItemResult._(isSuccess: false, isConflict: false, error: error);
  }

  factory SyncItemResult.conflict(Map<String, dynamic> serverData) {
    return SyncItemResult._(
      isSuccess: false,
      isConflict: true,
      serverData: serverData,
    );
  }
}

/// Sync status
class SyncStatus {
  final bool isActive;
  final int pendingCount;
  final int conflictCount;
  final DateTime? lastSyncTime;

  SyncStatus({
    required this.isActive,
    required this.pendingCount,
    required this.conflictCount,
    this.lastSyncTime,
  });
}

/// Conflict information
class ConflictInfo {
  final int id;
  final String tableName;
  final String recordId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final String conflictType;
  final DateTime createdAt;

  ConflictInfo({
    required this.id,
    required this.tableName,
    required this.recordId,
    required this.localData,
    required this.serverData,
    required this.conflictType,
    required this.createdAt,
  });
}