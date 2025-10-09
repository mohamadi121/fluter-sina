import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:collection';

/// Advanced Memory Management and Optimization System
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  // Memory pools for different object types
  final Map<Type, Queue<Object>> _objectPools = {};
  final Map<String, WeakReference<Object>> _weakReferences = {};
  final Set<String> _retainedObjects = {};
  
  // Memory monitoring
  Timer? _memoryCheckTimer;
  int _lastMemoryUsage = 0;
  final List<int> _memoryHistory = [];
  
  // Cache management
  final Map<String, _CacheEntry> _cache = {};
  int _cacheSize = 0;
  static const int _maxCacheSize = 50 * 1024 * 1024; // 50MB
  static const int _maxCacheEntries = 1000;
  
  // Listeners
  final List<VoidCallback> _memoryWarningCallbacks = [];
  final List<VoidCallback> _lowMemoryCallbacks = [];

  /// Initialize memory management
  void initialize() {
    startMemoryMonitoring();
    _initializeObjectPools();
  }

  /// Start memory monitoring
  void startMemoryMonitoring() {
    _memoryCheckTimer?.cancel();
    _memoryCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkMemoryUsage(),
    );
  }

  /// Stop memory monitoring
  void stopMemoryMonitoring() {
    _memoryCheckTimer?.cancel();
  }

  /// Initialize object pools for common types
  void _initializeObjectPools() {
    // Initialize pools for commonly used objects
    _objectPools[List] = Queue<Object>();
    _objectPools[Map] = Queue<Object>();
    _objectPools[Set] = Queue<Object>();
    _objectPools[StringBuffer] = Queue<Object>();
  }

  /// Get object from pool or create new one
  T getFromPool<T extends Object>(T Function() factory) {
    final pool = _objectPools[T];
    if (pool != null && pool.isNotEmpty) {
      return pool.removeFirst() as T;
    }
    return factory();
  }

  /// Return object to pool
  void returnToPool<T extends Object>(T object) {
    final pool = _objectPools[T] ??= Queue<Object>();
    
    // Reset object state if possible
    if (object is List) {
      object.clear();
    } else if (object is Map) {
      object.clear();
    } else if (object is Set) {
      object.clear();
    } else if (object is StringBuffer) {
      object.clear();
    }
    
    // Limit pool size to prevent memory leaks
    if (pool.length < 10) {
      pool.add(object);
    }
  }

  /// Create weak reference to object
  void createWeakReference(String key, Object object) {
    _weakReferences[key] = WeakReference(object);
  }

  /// Get object from weak reference
  T? getFromWeakReference<T extends Object>(String key) {
    final weakRef = _weakReferences[key];
    return weakRef?.target as T?;
  }

  /// Retain object in memory
  void retainObject(String key, Object object) {
    _retainedObjects.add(key);
    _cache[key] = _CacheEntry(
      object: object,
      timestamp: DateTime.now(),
      size: _estimateObjectSize(object),
    );
    _cacheSize += _cache[key]!.size;
    _enforceMemoryLimits();
  }

  /// Release retained object
  void releaseObject(String key) {
    _retainedObjects.remove(key);
    final entry = _cache.remove(key);
    if (entry != null) {
      _cacheSize -= entry.size;
    }
  }

  /// Get retained object
  T? getRetainedObject<T extends Object>(String key) {
    final entry = _cache[key];
    if (entry != null && _retainedObjects.contains(key)) {
      entry.timestamp = DateTime.now(); // Update access time
      return entry.object as T?;
    }
    return null;
  }

  /// Add memory warning callback
  void addMemoryWarningCallback(VoidCallback callback) {
    _memoryWarningCallbacks.add(callback);
  }

  /// Remove memory warning callback
  void removeMemoryWarningCallback(VoidCallback callback) {
    _memoryWarningCallbacks.remove(callback);
  }

  /// Add low memory callback
  void addLowMemoryCallback(VoidCallback callback) {
    _lowMemoryCallbacks.add(callback);
  }

  /// Remove low memory callback
  void removeLowMemoryCallback(VoidCallback callback) {
    _lowMemoryCallbacks.remove(callback);
  }

  /// Check memory usage and trigger callbacks if needed
  void _checkMemoryUsage() {
    final currentUsage = _estimateCurrentMemoryUsage();
    _memoryHistory.add(currentUsage);
    
    // Keep only recent history
    if (_memoryHistory.length > 60) { // 5 minutes of history
      _memoryHistory.removeAt(0);
    }
    
    // Check for memory pressure
    if (currentUsage > _lastMemoryUsage * 1.5) {
      _triggerMemoryWarning();
    }
    
    if (currentUsage > 200 * 1024 * 1024) { // 200MB threshold
      _triggerLowMemory();
    }
    
    _lastMemoryUsage = currentUsage;
  }

  /// Estimate current memory usage
  int _estimateCurrentMemoryUsage() {
    // This is a simplified estimation
    // In a real implementation, you would use platform-specific APIs
    return _cacheSize + (_objectPools.length * 1024);
  }

  /// Trigger memory warning callbacks
  void _triggerMemoryWarning() {
    if (kDebugMode) {
      debugPrint('Memory warning triggered');
    }
    
    for (final callback in _memoryWarningCallbacks) {
      try {
        callback();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error in memory warning callback: $e');
        }
      }
    }
    
    // Automatic cleanup
    _cleanupUnusedObjects();
  }

  /// Trigger low memory callbacks
  void _triggerLowMemory() {
    if (kDebugMode) {
      debugPrint('Low memory warning triggered');
    }
    
    for (final callback in _lowMemoryCallbacks) {
      try {
        callback();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error in low memory callback: $e');
        }
      }
    }
    
    // Aggressive cleanup
    _performAggressiveCleanup();
  }

  /// Cleanup unused objects
  void _cleanupUnusedObjects() {
    // Remove dead weak references
    _weakReferences.removeWhere((key, weakRef) => weakRef.target == null);
    
    // Clean old cache entries
    final now = DateTime.now();
    final oldEntries = _cache.entries
        .where((entry) => 
            !_retainedObjects.contains(entry.key) &&
            now.difference(entry.value.timestamp).inMinutes > 30)
        .map((entry) => entry.key)
        .toList();
    
    for (final key in oldEntries) {
      final entry = _cache.remove(key);
      if (entry != null) {
        _cacheSize -= entry.size;
      }
    }
    
    // Clear object pools
    for (final pool in _objectPools.values) {
      while (pool.length > 5) {
        pool.removeFirst();
      }
    }
  }

  /// Perform aggressive memory cleanup
  void _performAggressiveCleanup() {
    // Clear all non-retained cache entries
    final keysToRemove = _cache.keys
        .where((key) => !_retainedObjects.contains(key))
        .toList();
    
    for (final key in keysToRemove) {
      final entry = _cache.remove(key);
      if (entry != null) {
        _cacheSize -= entry.size;
      }
    }
    
    // Clear object pools
    _objectPools.clear();
    _initializeObjectPools();
    
    // Force garbage collection
    _forceGarbageCollection();
  }

  /// Enforce memory limits
  void _enforceMemoryLimits() {
    // Enforce cache size limit
    while (_cacheSize > _maxCacheSize || _cache.length > _maxCacheEntries) {
      // Remove oldest non-retained entry
      String? oldestKey;
      DateTime? oldestTime;
      
      for (final entry in _cache.entries) {
        if (!_retainedObjects.contains(entry.key)) {
          if (oldestTime == null || entry.value.timestamp.isBefore(oldestTime)) {
            oldestTime = entry.value.timestamp;
            oldestKey = entry.key;
          }
        }
      }
      
      if (oldestKey != null) {
        final entry = _cache.remove(oldestKey);
        if (entry != null) {
          _cacheSize -= entry.size;
        }
      } else {
        break; // All entries are retained
      }
    }
  }

  /// Estimate object size in bytes
  int _estimateObjectSize(Object object) {
    if (object is String) {
      return object.length * 2; // UTF-16 encoding
    } else if (object is List) {
      return object.length * 8 + 32; // Rough estimate
    } else if (object is Map) {
      return object.length * 16 + 32; // Rough estimate
    } else if (object is int) {
      return 8;
    } else if (object is double) {
      return 8;
    } else if (object is bool) {
      return 1;
    } else {
      return 64; // Default estimate for complex objects
    }
  }

  /// Force garbage collection (platform-specific implementation needed)
  void _forceGarbageCollection() {
    // In a real implementation, you would call platform-specific GC
    if (kDebugMode) {
      debugPrint('Forcing garbage collection');
    }
  }

  /// Get memory statistics
  MemoryStats getMemoryStats() {
    return MemoryStats(
      currentUsage: _estimateCurrentMemoryUsage(),
      cacheSize: _cacheSize,
      cacheEntries: _cache.length,
      retainedObjects: _retainedObjects.length,
      weakReferences: _weakReferences.length,
      objectPools: _objectPools.length,
      memoryHistory: List.unmodifiable(_memoryHistory),
    );
  }

  /// Clear all memory
  void clearAll() {
    _cache.clear();
    _retainedObjects.clear();
    _weakReferences.clear();
    _objectPools.clear();
    _cacheSize = 0;
    _memoryHistory.clear();
    _initializeObjectPools();
  }

  /// Dispose resources
  void dispose() {
    stopMemoryMonitoring();
    clearAll();
    _memoryWarningCallbacks.clear();
    _lowMemoryCallbacks.clear();
  }
}

/// Cache entry class
class _CacheEntry {
  _CacheEntry({
    required this.object,
    required this.timestamp,
    required this.size,
  });

  final Object object;
  DateTime timestamp;
  final int size;
}

/// Memory statistics
class MemoryStats {
  const MemoryStats({
    required this.currentUsage,
    required this.cacheSize,
    required this.cacheEntries,
    required this.retainedObjects,
    required this.weakReferences,
    required this.objectPools,
    required this.memoryHistory,
  });

  final int currentUsage;
  final int cacheSize;
  final int cacheEntries;
  final int retainedObjects;
  final int weakReferences;
  final int objectPools;
  final List<int> memoryHistory;

  /// Get memory usage in MB
  double get currentUsageMB => currentUsage / (1024 * 1024);
  
  /// Get cache size in MB
  double get cacheSizeMB => cacheSize / (1024 * 1024);
  
  /// Get average memory usage
  double get averageUsageMB {
    if (memoryHistory.isEmpty) return 0.0;
    final sum = memoryHistory.fold(0, (a, b) => a + b);
    return (sum / memoryHistory.length) / (1024 * 1024);
  }
}

/// Memory-aware widget base class
abstract class MemoryAwareWidget extends StatefulWidget {
  const MemoryAwareWidget({super.key});

  @override
  MemoryAwareWidgetState createState();
  
  /// Create the actual widget state
  MemoryAwareWidgetState createMemoryAwareState();
}

abstract class MemoryAwareWidgetState<T extends MemoryAwareWidget> 
    extends State<T> {
  final String _memoryKey = DateTime.now().millisecondsSinceEpoch.toString();
  
  @override
  void initState() {
    super.initState();
    MemoryManager().addMemoryWarningCallback(_onMemoryWarning);
    MemoryManager().addLowMemoryCallback(_onLowMemory);
  }

  @override
  void dispose() {
    MemoryManager().removeMemoryWarningCallback(_onMemoryWarning);
    MemoryManager().removeLowMemoryCallback(_onLowMemory);
    MemoryManager().releaseObject(_memoryKey);
    super.dispose();
  }

  /// Called when memory warning is triggered
  void _onMemoryWarning() {
    if (mounted) {
      onMemoryWarning();
    }
  }

  /// Called when low memory is triggered
  void _onLowMemory() {
    if (mounted) {
      onLowMemory();
    }
  }

  /// Override to handle memory warnings
  void onMemoryWarning() {}

  /// Override to handle low memory situations
  void onLowMemory() {}

  /// Retain object in memory
  void retainObject(String key, Object object) {
    MemoryManager().retainObject('${_memoryKey}_$key', object);
  }

  /// Get retained object
  T? getRetainedObject<T extends Object>(String key) {
    return MemoryManager().getRetainedObject<T>('${_memoryKey}_$key');
  }

  /// Release retained object
  void releaseRetainedObject(String key) {
    MemoryManager().releaseObject('${_memoryKey}_$key');
  }
}

/// Memory pool for reusable objects
class ObjectPool<T extends Object> {
  ObjectPool(this._factory, {this.maxSize = 10});

  final T Function() _factory;
  final int maxSize;
  final Queue<T> _pool = Queue<T>();

  /// Get object from pool or create new one
  T acquire() {
    if (_pool.isNotEmpty) {
      return _pool.removeFirst();
    }
    return _factory();
  }

  /// Return object to pool
  void release(T object) {
    if (_pool.length < maxSize) {
      // Reset object if possible
      if (object is List) {
        (object as List).clear();
      } else if (object is Map) {
        (object as Map).clear();
      } else if (object is Set) {
        (object as Set).clear();
      }
      
      _pool.add(object);
    }
  }

  /// Clear all objects from pool
  void clear() {
    _pool.clear();
  }

  /// Get current pool size
  int get size => _pool.length;
}

/// Memory-efficient list widget
class MemoryEfficientListView extends StatefulWidget {
  const MemoryEfficientListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.cacheExtent = 250.0,
    this.maxCacheSize = 100,
    this.itemExtent,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final double cacheExtent;
  final int maxCacheSize;
  final double? itemExtent;

  @override
  State<MemoryEfficientListView> createState() => _MemoryEfficientListViewState();
}

class _MemoryEfficientListViewState extends State<MemoryEfficientListView> {
  final Map<int, Widget> _cachedWidgets = {};
  final List<int> _accessOrder = [];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.itemCount,
      itemExtent: widget.itemExtent,
      cacheExtent: widget.cacheExtent,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemBuilder: (context, index) {
        return _getCachedWidget(index);
      },
    );
  }

  Widget _getCachedWidget(int index) {
    // Check cache first
    if (_cachedWidgets.containsKey(index)) {
      _updateAccessOrder(index);
      return _cachedWidgets[index]!;
    }

    // Build new widget
    final widget = this.widget.itemBuilder(context, index);
    
    // Add to cache
    _cachedWidgets[index] = widget;
    _updateAccessOrder(index);
    
    // Enforce cache size limit
    _enforceCacheLimit();
    
    return widget;
  }

  void _updateAccessOrder(int index) {
    _accessOrder.remove(index);
    _accessOrder.add(index);
  }

  void _enforceCacheLimit() {
    while (_cachedWidgets.length > widget.maxCacheSize && _accessOrder.isNotEmpty) {
      final oldestIndex = _accessOrder.removeAt(0);
      _cachedWidgets.remove(oldestIndex);
    }
  }

  @override
  void dispose() {
    _cachedWidgets.clear();
    _accessOrder.clear();
    super.dispose();
  }
}