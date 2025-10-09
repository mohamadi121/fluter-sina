import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../database/offline_database.dart';
import '../sync/background_sync_service.dart';
import '../network/enhanced_http_client.dart';
import '../firebase/firebase_manager.dart';
import '../../features/auth/services/security_service.dart';

/// Comprehensive Offline Manager for seamless offline experience
class OfflineManager {
  static final OfflineManager _instance = OfflineManager._internal();
  factory OfflineManager() => _instance;
  OfflineManager._internal();

  final OfflineDatabase _database = OfflineDatabase();
  final BackgroundSyncService _syncService = BackgroundSyncService();
  final EnhancedHttpClient _httpClient = EnhancedHttpClient();
  final SecurityService _security = SecurityService();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final StreamController<OfflineStatus> _statusController = StreamController<OfflineStatus>.broadcast();
  
  bool _isInitialized = false;
  bool _isOnline = false;
  OfflineMode _currentMode = OfflineMode.automatic;

  /// Stream of offline status changes
  Stream<OfflineStatus> get statusStream => _statusController.stream;

  /// Current online status
  bool get isOnline => _isOnline;

  /// Current offline mode
  OfflineMode get currentMode => _currentMode;

  /// Initialize offline manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize dependencies
      await _database.initialize();
      await _syncService.initialize();

      // Check initial connectivity
      await _updateConnectivityStatus();

      // Setup connectivity monitoring
      _setupConnectivityMonitoring();

      _isInitialized = true;

      await _security.logSecurityEvent(
        SecurityEventType.authSuccess,
        'Offline manager initialized',
        metadata: {
          'initial_online_status': _isOnline,
          'current_mode': _currentMode.name,
        },
      );

      // Emit initial status
      _emitStatus();

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Offline manager initialization failed');
      rethrow;
    }
  }

  /// Setup connectivity monitoring
  void _setupConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        await _updateConnectivityStatus();
        _emitStatus();
      },
    );
  }

  /// Update connectivity status
  Future<void> _updateConnectivityStatus() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      final wasOnline = _isOnline;
      
      _isOnline = connectivity.contains(ConnectivityResult.mobile) || 
                 connectivity.contains(ConnectivityResult.wifi);

      // Log connectivity changes
      if (wasOnline != _isOnline) {
        await _security.logSecurityEvent(
          SecurityEventType.authSuccess,
          'Connectivity status changed',
          metadata: {
            'was_online': wasOnline,
            'is_online': _isOnline,
            'connectivity_type': connectivity.map((c) => c.name).join(','),
          },
        );

        // Track analytics
        AnalyticsHelper.trackUserAction('connectivity_change', parameters: {
          'from_online': wasOnline,
          'to_online': _isOnline,
          'connectivity_types': connectivity.map((c) => c.name).toList(),
        });

        // Trigger sync when coming back online
        if (_isOnline && !wasOnline) {
          _handleConnectivityRestored();
        }
      }
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Update connectivity status failed');
    }
  }

  /// Handle connectivity restored
  Future<void> _handleConnectivityRestored() async {
    try {
      debugPrint('[OfflineManager] Connectivity restored, starting sync...');
      
      // Start background sync
      final syncResult = await _syncService.performSync();
      
      if (syncResult.isSuccess) {
        debugPrint('[OfflineManager] Sync completed successfully');
      } else {
        debugPrint('[OfflineManager] Sync failed: ${syncResult.message}');
      }
    } catch (e) {
      debugPrint('[OfflineManager] Handle connectivity restored failed: $e');
    }
  }

  /// Emit status update
  void _emitStatus() {
    _statusController.add(OfflineStatus(
      isOnline: _isOnline,
      mode: _currentMode,
      timestamp: DateTime.now(),
    ));
  }

  /// Set offline mode
  Future<void> setOfflineMode(OfflineMode mode) async {
    try {
      _currentMode = mode;
      
      await _security.logSecurityEvent(
        SecurityEventType.authSuccess,
        'Offline mode changed',
        metadata: {
          'new_mode': mode.name,
          'is_online': _isOnline,
        },
      );

      _emitStatus();
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Set offline mode failed');
    }
  }

  /// Save device data offline
  Future<void> saveDevice(Map<String, dynamic> deviceData) async {
    try {
      if (_shouldUseOfflineStorage()) {
        await _database.insertDevice(deviceData);
        
        await _security.logSecurityEvent(
          SecurityEventType.authSuccess,
          'Device saved offline',
          metadata: {
            'device_id': deviceData['id'],
            'is_online': _isOnline,
          },
        );
      } else {
        // Try to save online first
        try {
          final response = await _httpClient.post('/devices', data: deviceData);
          if (response.statusCode == 201) {
            // Save to local database as cache
            await _database.insertDevice({
              ...deviceData,
              'server_sync_status': 'synced',
            });
          }
        } catch (e) {
          // Fallback to offline storage
          await _database.insertDevice(deviceData);
        }
      }
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Save device offline failed');
      rethrow;
    }
  }

  /// Update device data offline
  Future<void> updateDevice(String deviceId, Map<String, dynamic> updates) async {
    try {
      if (_shouldUseOfflineStorage()) {
        await _database.updateDevice(deviceId, updates);
        
        await _security.logSecurityEvent(
          SecurityEventType.authSuccess,
          'Device updated offline',
          metadata: {
            'device_id': deviceId,
            'is_online': _isOnline,
          },
        );
      } else {
        // Try to update online first
        try {
          final response = await _httpClient.put('/devices/$deviceId', data: updates);
          if (response.statusCode == 200) {
            // Update local database
            await _database.updateDevice(deviceId, {
              ...updates,
              'server_sync_status': 'synced',
            });
          }
        } catch (e) {
          // Fallback to offline storage
          await _database.updateDevice(deviceId, updates);
        }
      }
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Update device offline failed');
      rethrow;
    }
  }

  /// Delete device offline
  Future<void> deleteDevice(String deviceId) async {
    try {
      if (_shouldUseOfflineStorage()) {
        await _database.deleteDevice(deviceId);
        
        await _security.logSecurityEvent(
          SecurityEventType.authSuccess,
          'Device deleted offline',
          metadata: {
            'device_id': deviceId,
            'is_online': _isOnline,
          },
        );
      } else {
        // Try to delete online first
        try {
          final response = await _httpClient.delete('/devices/$deviceId');
          if (response.statusCode == 200) {
            // Remove from local database
            await _database.deleteDevice(deviceId);
          }
        } catch (e) {
          // Fallback to offline storage
          await _database.deleteDevice(deviceId);
        }
      }
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Delete device offline failed');
      rethrow;
    }
  }

  /// Get device data (offline-first)
  Future<Map<String, dynamic>?> getDevice(String deviceId) async {
    try {
      // Always try local database first for speed
      final localDevice = await _database.getDevice(deviceId);
      
      if (localDevice != null) {
        return localDevice;
      }

      // If not found locally and online, try server
      if (_isOnline && _currentMode != OfflineMode.offlineOnly) {
        try {
          final response = await _httpClient.get('/devices/$deviceId');
          if (response.statusCode == 200) {
            final serverDevice = response.data as Map<String, dynamic>;
            
            // Cache server data locally
            await _database.insertDevice({
              ...serverDevice,
              'server_sync_status': 'synced',
            });
            
            return serverDevice;
          }
        } catch (e) {
          debugPrint('[OfflineManager] Failed to fetch device from server: $e');
        }
      }

      return null;
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Get device failed');
      return null;
    }
  }

  /// Get all devices (offline-first)
  Future<List<Map<String, dynamic>>> getAllDevices() async {
    try {
      // Always return local data first
      final localDevices = await _database.getAllDevices();
      
      // If online and not in offline-only mode, try to sync latest data
      if (_isOnline && _currentMode != OfflineMode.offlineOnly) {
        _syncDevicesInBackground();
      }
      
      return localDevices;
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Get all devices failed');
      return [];
    }
  }

  /// Sync devices in background
  Future<void> _syncDevicesInBackground() async {
    try {
      final response = await _httpClient.get('/devices');
      if (response.statusCode == 200) {
        final serverDevices = (response.data as List<dynamic>)
            .cast<Map<String, dynamic>>();
        
        // Update local database with server data
        for (final device in serverDevices) {
          await _database.insertDevice({
            ...device,
            'server_sync_status': 'synced',
          });
        }
      }
    } catch (e) {
      debugPrint('[OfflineManager] Background device sync failed: $e');
    }
  }

  /// Save energy data offline
  Future<void> saveEnergyData(Map<String, dynamic> energyData) async {
    try {
      await _database.insertEnergyData(energyData);
      
      await _security.logSecurityEvent(
        SecurityEventType.authSuccess,
        'Energy data saved offline',
        metadata: {
          'data_id': energyData['id'],
          'device_id': energyData['device_id'],
          'is_online': _isOnline,
        },
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Save energy data offline failed');
      rethrow;
    }
  }

  /// Get energy data for device (offline-first)
  Future<List<Map<String, dynamic>>> getEnergyDataForDevice(
    String deviceId, {
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) async {
    try {
      return await _database.getEnergyDataForDevice(
        deviceId,
        startTime: startTime,
        endTime: endTime,
        limit: limit,
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Get energy data failed');
      return [];
    }
  }

  /// Force sync with server
  Future<SyncResult> forceSync() async {
    try {
      if (!_isOnline) {
        return SyncResult.failed('No internet connection');
      }

      return await _syncService.forceSync();
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Force sync failed');
      return SyncResult.failed('Sync failed: ${e.toString()}');
    }
  }

  /// Get sync status
  Future<SyncStatus> getSyncStatus() async {
    return await _syncService.getSyncStatus();
  }

  /// Get unresolved conflicts
  Future<List<ConflictInfo>> getUnresolvedConflicts() async {
    return await _syncService.getUnresolvedConflicts();
  }

  /// Manually resolve conflict
  Future<void> resolveConflict(
    int conflictId,
    Map<String, dynamic> resolvedData,
  ) async {
    try {
      await _syncService.manuallyResolveConflict(conflictId, resolvedData);
      
      await _security.logSecurityEvent(
        SecurityEventType.authSuccess,
        'Conflict resolved manually',
        metadata: {
          'conflict_id': conflictId,
        },
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Resolve conflict failed');
      rethrow;
    }
  }

  /// Set conflict resolution strategy
  Future<void> setConflictResolutionStrategy(String strategy) async {
    await _syncService.setConflictResolutionStrategy(strategy);
  }

  /// Get offline statistics
  Future<OfflineStatistics> getOfflineStatistics() async {
    try {
      final dbStats = await _database.getDatabaseStats();
      final syncStatus = await _syncService.getSyncStatus();
      
      return OfflineStatistics(
        deviceCount: dbStats['device_count'] ?? 0,
        energyDataCount: dbStats['energy_count'] ?? 0,
        pendingSyncCount: dbStats['pending_sync_count'] ?? 0,
        conflictCount: dbStats['conflict_count'] ?? 0,
        lastSyncTime: syncStatus.lastSyncTime,
        isOnline: _isOnline,
        currentMode: _currentMode,
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Get offline statistics failed');
      return OfflineStatistics(
        deviceCount: 0,
        energyDataCount: 0,
        pendingSyncCount: 0,
        conflictCount: 0,
        lastSyncTime: null,
        isOnline: false,
        currentMode: OfflineMode.automatic,
      );
    }
  }

  /// Clear all offline data
  Future<void> clearOfflineData() async {
    try {
      await _database.clearAllData();
      
      await _security.logSecurityEvent(
        SecurityEventType.securityDataCleared,
        'All offline data cleared',
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Clear offline data failed');
      rethrow;
    }
  }

  /// Export offline data for backup
  Future<Map<String, dynamic>> exportOfflineData() async {
    try {
      final devices = await _database.getAllDevices();
      final energyData = await _database.getEnergyDataForDevice('all');
      final stats = await _database.getDatabaseStats();
      
      return {
        'export_timestamp': DateTime.now().millisecondsSinceEpoch,
        'devices': devices,
        'energy_data': energyData,
        'statistics': stats,
        'version': 1,
      };
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Export offline data failed');
      return {};
    }
  }

  /// Import offline data from backup
  Future<void> importOfflineData(Map<String, dynamic> backupData) async {
    try {
      final devices = backupData['devices'] as List<dynamic>?;
      final energyData = backupData['energy_data'] as List<dynamic>?;
      
      if (devices != null) {
        for (final device in devices) {
          await _database.insertDevice(device as Map<String, dynamic>);
        }
      }
      
      if (energyData != null) {
        for (final data in energyData) {
          await _database.insertEnergyData(data as Map<String, dynamic>);
        }
      }
      
      await _security.logSecurityEvent(
        SecurityEventType.authSuccess,
        'Offline data imported from backup',
        metadata: {
          'device_count': devices?.length ?? 0,
          'energy_data_count': energyData?.length ?? 0,
        },
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Import offline data failed');
      rethrow;
    }
  }

  /// Check if should use offline storage
  bool _shouldUseOfflineStorage() {
    switch (_currentMode) {
      case OfflineMode.automatic:
        return !_isOnline;
      case OfflineMode.offlineOnly:
        return true;
      case OfflineMode.onlineOnly:
        return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
    _syncService.dispose();
  }
}

/// Offline mode enumeration
enum OfflineMode {
  automatic, // Automatically switch between online/offline
  offlineOnly, // Force offline mode
  onlineOnly, // Force online mode (fail if offline)
}

/// Offline status data class
class OfflineStatus {
  final bool isOnline;
  final OfflineMode mode;
  final DateTime timestamp;

  OfflineStatus({
    required this.isOnline,
    required this.mode,
    required this.timestamp,
  });
}

/// Offline statistics data class
class OfflineStatistics {
  final int deviceCount;
  final int energyDataCount;
  final int pendingSyncCount;
  final int conflictCount;
  final DateTime? lastSyncTime;
  final bool isOnline;
  final OfflineMode currentMode;

  OfflineStatistics({
    required this.deviceCount,
    required this.energyDataCount,
    required this.pendingSyncCount,
    required this.conflictCount,
    this.lastSyncTime,
    required this.isOnline,
    required this.currentMode,
  });
}