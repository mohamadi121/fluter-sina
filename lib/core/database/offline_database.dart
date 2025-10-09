import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_manager.dart';
import '../network/enhanced_http_client.dart';
import '../../features/auth/services/security_service.dart';

/// Advanced Offline Database Manager with synchronization capabilities
class OfflineDatabase {
  static final OfflineDatabase _instance = OfflineDatabase._internal();
  factory OfflineDatabase() => _instance;
  OfflineDatabase._internal();

  Database? _database;
  final SecurityService _security = SecurityService();
  
  // Database configuration
  static const String _databaseName = 'smarthome_offline.db';
  static const int _databaseVersion = 1;
  
  // Table names
  static const String _devicesTable = 'devices';
  static const String _energyDataTable = 'energy_data';
  static const String _syncQueueTable = 'sync_queue';
  static const String _conflictsTable = 'conflicts';
  static const String _metadataTable = 'metadata';

  /// Initialize database
  Future<void> initialize() async {
    if (_database != null) return;

    try {
      final documentsDirectory = await getDatabasesPath();
      final path = join(documentsDirectory, _databaseName);

      _database = await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
        onOpen: _onDatabaseOpen,
      );

      await _security.logSecurityEvent(
        SecurityEventType.authSuccess,
        'Offline database initialized',
        metadata: {
          'database_path': path,
          'version': _databaseVersion,
        },
      );

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Database initialization failed');
      rethrow;
    }
  }

  /// Create database tables
  Future<void> _createDatabase(Database db, int version) async {
    // Devices table
    await db.execute('''
      CREATE TABLE $_devicesTable (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        room TEXT NOT NULL,
        is_online INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        battery_level INTEGER,
        energy_usage REAL,
        last_update INTEGER NOT NULL,
        server_sync_status TEXT DEFAULT 'pending',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        version INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Energy data table
    await db.execute('''
      CREATE TABLE $_energyDataTable (
        id TEXT PRIMARY KEY,
        device_id TEXT,
        timestamp INTEGER NOT NULL,
        consumption REAL NOT NULL,
        cost REAL NOT NULL,
        type TEXT DEFAULT 'reading',
        server_sync_status TEXT DEFAULT 'pending',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        version INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (device_id) REFERENCES $_devicesTable (id) ON DELETE CASCADE
      )
    ''');

    // Sync queue table
    await db.execute('''
      CREATE TABLE $_syncQueueTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        priority INTEGER DEFAULT 0,
        retry_count INTEGER DEFAULT 0,
        last_attempt INTEGER,
        created_at INTEGER NOT NULL,
        status TEXT DEFAULT 'pending'
      )
    ''');

    // Conflicts table
    await db.execute('''
      CREATE TABLE $_conflictsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        local_data TEXT NOT NULL,
        server_data TEXT NOT NULL,
        conflict_type TEXT NOT NULL,
        resolution_strategy TEXT,
        resolved INTEGER DEFAULT 0,
        created_at INTEGER NOT NULL,
        resolved_at INTEGER
      )
    ''');

    // Metadata table
    await db.execute('''
      CREATE TABLE $_metadataTable (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_devices_sync_status ON $_devicesTable(server_sync_status)');
    await db.execute('CREATE INDEX idx_devices_updated_at ON $_devicesTable(updated_at)');
    await db.execute('CREATE INDEX idx_energy_timestamp ON $_energyDataTable(timestamp)');
    await db.execute('CREATE INDEX idx_energy_sync_status ON $_energyDataTable(server_sync_status)');
    await db.execute('CREATE INDEX idx_sync_queue_status ON $_syncQueueTable(status)');
    await db.execute('CREATE INDEX idx_sync_queue_priority ON $_syncQueueTable(priority DESC)');
  }

  /// Upgrade database schema
  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    // Handle database schema upgrades
    if (oldVersion < newVersion) {
      // Add migration logic here for future versions
      debugPrint('[Database] Upgrading from version $oldVersion to $newVersion');
    }
  }

  /// Handle database open
  Future<void> _onDatabaseOpen(Database db) async {
    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys = ON');
    // Set journal mode for better performance
    await db.execute('PRAGMA journal_mode = WAL');
    // Set synchronous mode
    await db.execute('PRAGMA synchronous = NORMAL');
  }

  /// Get database instance
  Database get database {
    if (_database == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }
    return _database!;
  }

  /// Insert device
  Future<void> insertDevice(Map<String, dynamic> device) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final deviceData = {
        ...device,
        'created_at': now,
        'updated_at': now,
        'version': 1,
        'server_sync_status': 'pending',
      };

      await database.insert(
        _devicesTable,
        deviceData,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Add to sync queue
      await _addToSyncQueue(_devicesTable, device['id'], 'insert', deviceData);

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Insert device failed');
      rethrow;
    }
  }

  /// Update device
  Future<void> updateDevice(String deviceId, Map<String, dynamic> updates) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Get current device data
      final currentDevice = await getDevice(deviceId);
      if (currentDevice == null) {
        throw Exception('Device not found: $deviceId');
      }

      final updatedData = {
        ...currentDevice,
        ...updates,
        'updated_at': now,
        'version': (currentDevice['version'] ?? 0) + 1,
        'server_sync_status': 'pending',
      };

      await database.update(
        _devicesTable,
        updatedData,
        where: 'id = ?',
        whereArgs: [deviceId],
      );

      // Add to sync queue
      await _addToSyncQueue(_devicesTable, deviceId, 'update', updatedData);

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Update device failed');
      rethrow;
    }
  }

  /// Delete device
  Future<void> deleteDevice(String deviceId) async {
    try {
      await database.delete(
        _devicesTable,
        where: 'id = ?',
        whereArgs: [deviceId],
      );

      // Add to sync queue
      await _addToSyncQueue(_devicesTable, deviceId, 'delete', {'id': deviceId});

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Delete device failed');
      rethrow;
    }
  }

  /// Get device by ID
  Future<Map<String, dynamic>?> getDevice(String deviceId) async {
    try {
      final results = await database.query(
        _devicesTable,
        where: 'id = ?',
        whereArgs: [deviceId],
      );

      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Get device failed');
      return null;
    }
  }

  /// Get all devices
  Future<List<Map<String, dynamic>>> getAllDevices() async {
    try {
      return await database.query(
        _devicesTable,
        orderBy: 'updated_at DESC',
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Get all devices failed');
      return [];
    }
  }

  /// Insert energy data
  Future<void> insertEnergyData(Map<String, dynamic> energyData) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final data = {
        ...energyData,
        'created_at': now,
        'updated_at': now,
        'version': 1,
        'server_sync_status': 'pending',
      };

      await database.insert(
        _energyDataTable,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Add to sync queue
      await _addToSyncQueue(_energyDataTable, energyData['id'], 'insert', data);

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Insert energy data failed');
      rethrow;
    }
  }

  /// Get energy data for device
  Future<List<Map<String, dynamic>>> getEnergyDataForDevice(
    String deviceId, {
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) async {
    try {
      String whereClause = 'device_id = ?';
      List<dynamic> whereArgs = [deviceId];

      if (startTime != null) {
        whereClause += ' AND timestamp >= ?';
        whereArgs.add(startTime.millisecondsSinceEpoch);
      }

      if (endTime != null) {
        whereClause += ' AND timestamp <= ?';
        whereArgs.add(endTime.millisecondsSinceEpoch);
      }

      return await database.query(
        _energyDataTable,
        where: whereClause,
        whereArgs: whereArgs,
        orderBy: 'timestamp DESC',
        limit: limit,
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Get energy data failed');
      return [];
    }
  }

  /// Add record to sync queue
  Future<void> _addToSyncQueue(
    String tableName,
    String recordId,
    String operation,
    Map<String, dynamic> data, {
    int priority = 0,
  }) async {
    try {
      await database.insert(_syncQueueTable, {
        'table_name': tableName,
        'record_id': recordId,
        'operation': operation,
        'data': jsonEncode(data),
        'priority': priority,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'status': 'pending',
      });
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Add to sync queue failed');
    }
  }

  /// Get pending sync items
  Future<List<Map<String, dynamic>>> getPendingSyncItems({int? limit}) async {
    try {
      return await database.query(
        _syncQueueTable,
        where: 'status = ?',
        whereArgs: ['pending'],
        orderBy: 'priority DESC, created_at ASC',
        limit: limit,
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Get pending sync items failed');
      return [];
    }
  }

  /// Mark sync item as completed
  Future<void> markSyncCompleted(int syncId) async {
    try {
      await database.update(
        _syncQueueTable,
        {
          'status': 'completed',
          'last_attempt': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [syncId],
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Mark sync completed failed');
    }
  }

  /// Mark sync item as failed
  Future<void> markSyncFailed(int syncId, {String? error}) async {
    try {
      final currentItem = await database.query(
        _syncQueueTable,
        where: 'id = ?',
        whereArgs: [syncId],
      );

      if (currentItem.isNotEmpty) {
        final retryCount = (currentItem.first['retry_count'] as int? ?? 0) + 1;
        
        await database.update(
          _syncQueueTable,
          {
            'status': retryCount >= 3 ? 'failed' : 'pending',
            'retry_count': retryCount,
            'last_attempt': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [syncId],
        );
      }
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Mark sync failed failed');
    }
  }

  /// Add conflict record
  Future<void> addConflict({
    required String tableName,
    required String recordId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
    required String conflictType,
  }) async {
    try {
      await database.insert(_conflictsTable, {
        'table_name': tableName,
        'record_id': recordId,
        'local_data': jsonEncode(localData),
        'server_data': jsonEncode(serverData),
        'conflict_type': conflictType,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Add conflict failed');
    }
  }

  /// Get unresolved conflicts
  Future<List<Map<String, dynamic>>> getUnresolvedConflicts() async {
    try {
      return await database.query(
        _conflictsTable,
        where: 'resolved = ?',
        whereArgs: [0],
        orderBy: 'created_at ASC',
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Get unresolved conflicts failed');
      return [];
    }
  }

  /// Resolve conflict
  Future<void> resolveConflict(
    int conflictId,
    String resolutionStrategy,
    Map<String, dynamic> resolvedData,
  ) async {
    try {
      await database.transaction((txn) async {
        // Mark conflict as resolved
        await txn.update(
          _conflictsTable,
          {
            'resolved': 1,
            'resolution_strategy': resolutionStrategy,
            'resolved_at': DateTime.now().millisecondsSinceEpoch,
          },
          where: 'id = ?',
          whereArgs: [conflictId],
        );

        // Get conflict details
        final conflicts = await txn.query(
          _conflictsTable,
          where: 'id = ?',
          whereArgs: [conflictId],
        );

        if (conflicts.isNotEmpty) {
          final conflict = conflicts.first;
          final tableName = conflict['table_name'] as String;
          final recordId = conflict['record_id'] as String;

          // Update the actual record
          await txn.update(
            tableName,
            {
              ...resolvedData,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
              'server_sync_status': 'synced',
            },
            where: 'id = ?',
            whereArgs: [recordId],
          );
        }
      });
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Resolve conflict failed');
      rethrow;
    }
  }

  /// Set metadata
  Future<void> setMetadata(String key, String value) async {
    try {
      await database.insert(
        _metadataTable,
        {
          'key': key,
          'value': value,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Set metadata failed');
    }
  }

  /// Get metadata
  Future<String?> getMetadata(String key) async {
    try {
      final results = await database.query(
        _metadataTable,
        where: 'key = ?',
        whereArgs: [key],
      );

      return results.isNotEmpty ? results.first['value'] as String? : null;
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Get metadata failed');
      return null;
    }
  }

  /// Clear all data
  Future<void> clearAllData() async {
    try {
      await database.transaction((txn) async {
        await txn.delete(_devicesTable);
        await txn.delete(_energyDataTable);
        await txn.delete(_syncQueueTable);
        await txn.delete(_conflictsTable);
        await txn.delete(_metadataTable);
      });

      await _security.logSecurityEvent(
        SecurityEventType.securityDataCleared,
        'All offline data cleared',
      );
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Clear all data failed');
      rethrow;
    }
  }

  /// Get database statistics
  Future<Map<String, dynamic>> getDatabaseStats() async {
    try {
      final deviceCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM $_devicesTable'),
      );
      
      final energyCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM $_energyDataTable'),
      );
      
      final pendingSyncCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM $_syncQueueTable WHERE status = ?', ['pending']),
      );
      
      final conflictCount = Sqflite.firstIntValue(
        await database.rawQuery('SELECT COUNT(*) FROM $_conflictsTable WHERE resolved = ?', [0]),
      );

      return {
        'device_count': deviceCount ?? 0,
        'energy_count': energyCount ?? 0,
        'pending_sync_count': pendingSyncCount ?? 0,
        'conflict_count': conflictCount ?? 0,
      };
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Get database stats failed');
      return {};
    }
  }

  /// Close database
  Future<void> close() async {
    try {
      await _database?.close();
      _database = null;
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Close database failed');
    }
  }
}