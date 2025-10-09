import 'dart:async';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_manager.dart';
import 'performance_monitor.dart';
import 'battery_optimizer.dart';
import '../../features/auth/services/security_service.dart';

/// Firebase Performance Integration with custom monitoring
class FirebasePerformanceService {
  static final FirebasePerformanceService _instance = FirebasePerformanceService._internal();
  factory FirebasePerformanceService() => _instance;
  FirebasePerformanceService._internal();

  late final FirebasePerformance _firebasePerformance;
  final PerformanceMonitor _performanceMonitor = PerformanceMonitor();
  final BatteryOptimizer _batteryOptimizer = BatteryOptimizer();
  final SecurityService _security = SecurityService();
  
  // Active traces
  final Map<String, Trace> _activeTraces = {};
  final Map<String, HttpMetric> _activeHttpMetrics = {};
  
  // Custom metrics tracking
  Timer? _metricsTimer;
  final Map<String, CustomMetric> _customMetrics = {};
  
  // Performance data collection
  final List<PerformanceSnapshot> _performanceSnapshots = [];
  final List<BatterySnapshot> _batterySnapshots = [];
  
  bool _isInitialized = false;
  bool _isCollectingMetrics = false;
  
  static const Duration _metricsInterval = Duration(minutes: 1);
  static const int _maxSnapshotsCount = 100;

  /// Initialize Firebase Performance service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _firebasePerformance = FirebasePerformance.instance;
      
      // Enable automatic screen trace tracking
      await _setupAutomaticTracing();
      
      // Setup custom metrics collection
      _setupCustomMetricsCollection();
      
      // Register performance data collection
      _startPerformanceDataCollection();
      
      _isInitialized = true;
      
      await _security.logSecurityEvent(
        SecurityEventType.authSuccess,
        'Firebase Performance service initialized',
        metadata: {
          'automatic_tracing_enabled': true,
          'custom_metrics_enabled': true,
          'data_collection_interval_minutes': _metricsInterval.inMinutes,
        },
      );

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Firebase Performance initialization failed');
      rethrow;
    }
  }

  /// Setup automatic tracing
  Future<void> _setupAutomaticTracing() async {
    try {
      // Enable automatic activity recognition
      // This is handled automatically by Firebase Performance SDK
      debugPrint('[FirebasePerformance] Automatic screen tracing enabled');
      
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Setup automatic tracing failed');
    }
  }

  /// Setup custom metrics collection
  void _setupCustomMetricsCollection() {
    try {
      // Initialize custom metrics
      _initializeCustomMetrics();
      
      // Start periodic metrics collection
      _metricsTimer = Timer.periodic(_metricsInterval, (timer) {
        _collectCustomMetrics();
      });
      
      _isCollectingMetrics = true;
      
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Setup custom metrics collection failed');
    }
  }

  /// Initialize custom metrics
  void _initializeCustomMetrics() {
    try {
      _customMetrics['app_fps'] = CustomMetric(
        name: 'app_fps',
        unit: 'fps',
        description: 'Application frames per second',
      );
      
      _customMetrics['memory_usage'] = CustomMetric(
        name: 'memory_usage',
        unit: 'mb',
        description: 'Application memory usage in megabytes',
      );
      
      _customMetrics['battery_level'] = CustomMetric(
        name: 'battery_level',
        unit: 'percent',
        description: 'Device battery level percentage',
      );
      
      _customMetrics['battery_consumption'] = CustomMetric(
        name: 'battery_consumption',
        unit: 'ma',
        description: 'Estimated battery consumption in milliamperes',
      );
      
      _customMetrics['network_latency'] = CustomMetric(
        name: 'network_latency',
        unit: 'ms',
        description: 'Average network request latency',
      );
      
      _customMetrics['network_requests_count'] = CustomMetric(
        name: 'network_requests_count',
        unit: 'count',
        description: 'Number of network requests per minute',
      );
      
    } catch (e) {
      debugPrint('[FirebasePerformance] Initialize custom metrics failed: $e');
    }
  }

  /// Start performance data collection
  void _startPerformanceDataCollection() {
    try {
      // Listen to performance monitor
      _performanceMonitor.metricsStream.listen((metrics) {
        _collectPerformanceSnapshot(metrics);
      });
      
      // Listen to battery optimizer
      _batteryOptimizer.statusStream.listen((status) {
        _collectBatterySnapshot(status);
      });
      
    } catch (e) {
      debugPrint('[FirebasePerformance] Start performance data collection failed: $e');
    }
  }

  /// Collect custom metrics
  Future<void> _collectCustomMetrics() async {
    try {
      if (!_isInitialized) return;
      
      // Get current performance statistics
      final performanceStats = _performanceMonitor.getPerformanceStatistics();
      final batteryStats = _batteryOptimizer.getBatteryStatistics();
      
      // Update custom metrics
      await _updateCustomMetric('app_fps', performanceStats.currentFPS);
      await _updateCustomMetric('memory_usage', performanceStats.currentMemoryMB);
      await _updateCustomMetric('battery_level', batteryStats.currentLevel.toDouble());
      await _updateCustomMetric('battery_consumption', batteryStats.currentConsumptionMA);
      await _updateCustomMetric('network_latency', performanceStats.averageResponseTimeMS);
      await _updateCustomMetric('network_requests_count', performanceStats.networkRequestCount.toDouble());
      
      // Log comprehensive performance data
      AnalyticsHelper.trackUserAction('firebase_performance_metrics', parameters: {
        'app_fps': performanceStats.currentFPS,
        'memory_usage_mb': performanceStats.currentMemoryMB,
        'battery_level': batteryStats.currentLevel,
        'battery_consumption_ma': batteryStats.currentConsumptionMA,
        'network_latency_ms': performanceStats.averageResponseTimeMS,
        'network_requests_count': performanceStats.networkRequestCount,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Collect custom metrics failed');
    }
  }

  /// Update custom metric
  Future<void> _updateCustomMetric(String metricName, double value) async {
    try {
      final metric = _customMetrics[metricName];
      if (metric == null) return;
      
      // Update metric value
      metric.lastValue = value;
      metric.lastUpdate = DateTime.now();
      metric.sampleCount++;
      
      // Calculate running average
      if (metric.totalValue == 0) {
        metric.totalValue = value;
        metric.averageValue = value;
      } else {
        metric.totalValue += value;
        metric.averageValue = metric.totalValue / metric.sampleCount;
      }
      
      // Track min/max
      if (value < metric.minValue || metric.minValue == 0) {
        metric.minValue = value;
      }
      if (value > metric.maxValue) {
        metric.maxValue = value;
      }
      
    } catch (e) {
      debugPrint('[FirebasePerformance] Update custom metric failed: $e');
    }
  }

  /// Collect performance snapshot
  void _collectPerformanceSnapshot(PerformanceMetrics metrics) {
    try {
      final snapshot = PerformanceSnapshot(
        timestamp: DateTime.now(),
        fps: metrics.fps,
        memoryUsageMB: metrics.memoryUsageMB,
        networkLatencyMS: metrics.networkLatencyMS,
        isPerformanceGood: metrics.isPerformanceGood,
        warningsCount: metrics.warnings.length,
      );
      
      _performanceSnapshots.add(snapshot);
      
      // Keep snapshots manageable
      if (_performanceSnapshots.length > _maxSnapshotsCount) {
        _performanceSnapshots.removeAt(0);
      }
      
      // Log performance issues
      if (!metrics.isPerformanceGood) {
        _logPerformanceIssue(metrics);
      }
      
    } catch (e) {
      debugPrint('[FirebasePerformance] Collect performance snapshot failed: $e');
    }
  }

  /// Collect battery snapshot
  void _collectBatterySnapshot(BatteryStatus status) {
    try {
      final snapshot = BatterySnapshot(
        timestamp: DateTime.now(),
        batteryLevel: status.batteryLevel,
        batteryState: status.batteryState,
        powerConsumptionMA: status.powerConsumptionMA,
        optimizationMode: status.optimizationMode,
        isOptimizing: status.isOptimizing,
        activeStrategiesCount: status.activeStrategies.length,
      );
      
      _batterySnapshots.add(snapshot);
      
      // Keep snapshots manageable
      if (_batterySnapshots.length > _maxSnapshotsCount) {
        _batterySnapshots.removeAt(0);
      }
      
      // Log battery optimization events
      if (status.batteryLevel <= 20) {
        _logBatteryOptimizationEvent(status);
      }
      
    } catch (e) {
      debugPrint('[FirebasePerformance] Collect battery snapshot failed: $e');
    }
  }

  /// Log performance issue
  Future<void> _logPerformanceIssue(PerformanceMetrics metrics) async {
    try {
      await _security.logSecurityEvent(
        SecurityEventType.suspiciousActivity,
        'Performance issue detected',
        metadata: {
          'fps': metrics.fps,
          'memory_usage_mb': metrics.memoryUsageMB,
          'network_latency_ms': metrics.networkLatencyMS,
          'warnings_count': metrics.warnings.length,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      
      // Create custom trace for performance issue
      final trace = _firebasePerformance.newTrace('performance_issue');
      trace.start();
      
      // Add custom attributes
      trace.putAttribute('fps', metrics.fps.toStringAsFixed(1));
      trace.putAttribute('memory_mb', metrics.memoryUsageMB.toStringAsFixed(0));
      trace.putAttribute('network_latency', metrics.networkLatencyMS.toStringAsFixed(0));
      trace.putAttribute('warnings_count', metrics.warnings.length.toString());
      
      // Add custom metrics
      trace.putMetric('fps_metric', metrics.fps.toInt());
      trace.putMetric('memory_metric', metrics.memoryUsageMB.toInt());
      trace.putMetric('latency_metric', metrics.networkLatencyMS.toInt());
      
      trace.stop();
      
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Log performance issue failed');
    }
  }

  /// Log battery optimization event
  Future<void> _logBatteryOptimizationEvent(BatteryStatus status) async {
    try {
      // Create custom trace for battery optimization
      final trace = _firebasePerformance.newTrace('battery_optimization');
      trace.start();
      
      // Add custom attributes
      trace.putAttribute('battery_level', status.batteryLevel.toString());
      trace.putAttribute('battery_state', status.batteryState.name);
      trace.putAttribute('power_consumption', status.powerConsumptionMA.toStringAsFixed(0));
      trace.putAttribute('optimization_mode', status.optimizationMode.name);
      trace.putAttribute('strategies_count', status.activeStrategies.length.toString());
      
      // Add custom metrics
      trace.putMetric('battery_level_metric', status.batteryLevel);
      trace.putMetric('power_consumption_metric', status.powerConsumptionMA.toInt());
      trace.putMetric('strategies_metric', status.activeStrategies.length);
      
      trace.stop();
      
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Log battery optimization event failed');
    }
  }

  /// Start custom trace
  Future<Trace> startTrace(String traceName) async {
    try {
      if (!_isInitialized) {
        throw Exception('Firebase Performance not initialized');
      }
      
      final trace = _firebasePerformance.newTrace(traceName);
      await trace.start();
      
      _activeTraces[traceName] = trace;
      
      return trace;
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Start trace failed');
      rethrow;
    }
  }

  /// Stop custom trace
  Future<void> stopTrace(String traceName, {Map<String, String>? attributes, Map<String, int>? metrics}) async {
    try {
      final trace = _activeTraces[traceName];
      if (trace == null) return;
      
      // Add attributes if provided
      if (attributes != null) {
        for (final entry in attributes.entries) {
          trace.putAttribute(entry.key, entry.value);
        }
      }
      
      // Add metrics if provided
      if (metrics != null) {
        for (final entry in metrics.entries) {
          trace.putMetric(entry.key, entry.value);
        }
      }
      
      await trace.stop();
      _activeTraces.remove(traceName);
      
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Stop trace failed');
    }
  }

  /// Start HTTP metric
  Future<HttpMetric> startHttpMetric(String url, HttpMethod method) async {
    try {
      if (!_isInitialized) {
        throw Exception('Firebase Performance not initialized');
      }
      
      final httpMetric = _firebasePerformance.newHttpMetric(url, method);
      await httpMetric.start();
      
      final key = '${method.name}_$url';
      _activeHttpMetrics[key] = httpMetric;
      
      return httpMetric;
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Start HTTP metric failed');
      rethrow;
    }
  }

  /// Stop HTTP metric
  Future<void> stopHttpMetric(String url, HttpMethod method, {
    int? responseCode,
    int? requestPayloadSize,
    int? responsePayloadSize,
    String? contentType,
  }) async {
    try {
      final key = '${method.name}_$url';
      final httpMetric = _activeHttpMetrics[key];
      if (httpMetric == null) return;
      
      // Set response details
      if (responseCode != null) {
        httpMetric.responseCode = responseCode;
      }
      if (requestPayloadSize != null) {
        httpMetric.requestPayloadSize = requestPayloadSize;
      }
      if (responsePayloadSize != null) {
        httpMetric.responsePayloadSize = responsePayloadSize;
      }
      if (contentType != null) {
        httpMetric.responseContentType = contentType;
      }
      
      await httpMetric.stop();
      _activeHttpMetrics.remove(key);
      
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Stop HTTP metric failed');
    }
  }

  /// Track screen view
  Future<void> trackScreenView(String screenName, {Map<String, String>? attributes}) async {
    try {
      final trace = await startTrace('screen_$screenName');
      
      // Add screen attributes
      trace.putAttribute('screen_name', screenName);
      if (attributes != null) {
        for (final entry in attributes.entries) {
          trace.putAttribute(entry.key, entry.value);
        }
      }
      
      // Auto-stop after a reasonable time for screen views
      Timer(const Duration(seconds: 30), () {
        stopTrace('screen_$screenName');
      });
      
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Track screen view failed');
    }
  }

  /// Track user interaction
  Future<void> trackUserInteraction(String action, {
    String? target,
    Map<String, String>? attributes,
    Map<String, int>? metrics,
  }) async {
    try {
      final traceName = 'user_interaction_$action';
      final trace = await startTrace(traceName);
      
      // Add interaction attributes
      trace.putAttribute('action', action);
      if (target != null) {
        trace.putAttribute('target', target);
      }
      if (attributes != null) {
        for (final entry in attributes.entries) {
          trace.putAttribute(entry.key, entry.value);
        }
      }
      
      // Auto-stop after interaction
      Timer(const Duration(seconds: 5), () {
        stopTrace(traceName, metrics: metrics);
      });
      
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Track user interaction failed');
    }
  }

  /// Track app startup performance
  Future<void> trackAppStartup() async {
    try {
      final trace = await startTrace('app_startup');
      
      // Add startup attributes
      trace.putAttribute('app_version', '1.0.0'); // Get from package info
      trace.putAttribute('platform', defaultTargetPlatform.name);
      
      // This should be called when app is fully loaded
      Timer(const Duration(seconds: 3), () {
        stopTrace('app_startup', metrics: {
          'startup_time_ms': 3000,
        });
      });
      
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Track app startup failed');
    }
  }

  /// Get performance summary
  PerformanceSummary getPerformanceSummary() {
    try {
      final recentPerformance = _performanceSnapshots.length >= 10
          ? _performanceSnapshots.sublist(_performanceSnapshots.length - 10)
          : _performanceSnapshots;
      
      final recentBattery = _batterySnapshots.length >= 10
          ? _batterySnapshots.sublist(_batterySnapshots.length - 10)
          : _batterySnapshots;
      
      final averageFPS = recentPerformance.isNotEmpty
          ? recentPerformance.fold<double>(0.0, (sum, s) => sum + s.fps) / recentPerformance.length
          : 0.0;
      
      final averageMemory = recentPerformance.isNotEmpty
          ? recentPerformance.fold<double>(0.0, (sum, s) => sum + s.memoryUsageMB) / recentPerformance.length
          : 0.0;
      
      final averageBatteryConsumption = recentBattery.isNotEmpty
          ? recentBattery.fold<double>(0.0, (sum, s) => sum + s.powerConsumptionMA) / recentBattery.length
          : 0.0;
      
      return PerformanceSummary(
        averageFPS: averageFPS,
        averageMemoryUsageMB: averageMemory,
        averageBatteryConsumptionMA: averageBatteryConsumption,
        performanceSnapshotsCount: _performanceSnapshots.length,
        batterySnapshotsCount: _batterySnapshots.length,
        customMetricsCount: _customMetrics.length,
        activeTracesCount: _activeTraces.length,
        activeHttpMetricsCount: _activeHttpMetrics.length,
        isCollectingMetrics: _isCollectingMetrics,
      );
    } catch (e) {
      return PerformanceSummary(
        averageFPS: 0.0,
        averageMemoryUsageMB: 0.0,
        averageBatteryConsumptionMA: 0.0,
        performanceSnapshotsCount: 0,
        batterySnapshotsCount: 0,
        customMetricsCount: 0,
        activeTracesCount: 0,
        activeHttpMetricsCount: 0,
        isCollectingMetrics: false,
      );
    }
  }

  /// Export Firebase performance data
  Map<String, dynamic> exportFirebasePerformanceData() {
    try {
      return {
        'export_timestamp': DateTime.now().millisecondsSinceEpoch,
        'firebase_performance_enabled': _isInitialized,
        'metrics_collection_enabled': _isCollectingMetrics,
        'custom_metrics': _customMetrics.map((key, metric) => 
            MapEntry(key, metric.toJson())),
        'performance_snapshots': _performanceSnapshots
            .map((snapshot) => snapshot.toJson())
            .toList(),
        'battery_snapshots': _batterySnapshots
            .map((snapshot) => snapshot.toJson())
            .toList(),
        'active_traces': _activeTraces.keys.toList(),
        'active_http_metrics': _activeHttpMetrics.keys.toList(),
        'summary': getPerformanceSummary().toJson(),
      };
    } catch (e) {
      return {
        'error': 'Failed to export Firebase Performance data: ${e.toString()}',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  /// Stop metrics collection
  void stopMetricsCollection() {
    _metricsTimer?.cancel();
    _isCollectingMetrics = false;
  }

  /// Dispose Firebase Performance service
  void dispose() {
    _metricsTimer?.cancel();
    
    // Stop all active traces
    for (final trace in _activeTraces.values) {
      try {
        trace.stop();
      } catch (e) {
        debugPrint('[FirebasePerformance] Failed to stop trace: $e');
      }
    }
    
    // Stop all active HTTP metrics
    for (final httpMetric in _activeHttpMetrics.values) {
      try {
        httpMetric.stop();
      } catch (e) {
        debugPrint('[FirebasePerformance] Failed to stop HTTP metric: $e');
      }
    }
    
    _activeTraces.clear();
    _activeHttpMetrics.clear();
    _customMetrics.clear();
    _performanceSnapshots.clear();
    _batterySnapshots.clear();
  }
}

/// Custom metric class
class CustomMetric {
  final String name;
  final String unit;
  final String description;
  
  double lastValue = 0.0;
  double totalValue = 0.0;
  double averageValue = 0.0;
  double minValue = 0.0;
  double maxValue = 0.0;
  int sampleCount = 0;
  DateTime lastUpdate = DateTime.now();

  CustomMetric({
    required this.name,
    required this.unit,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'unit': unit,
      'description': description,
      'last_value': lastValue,
      'average_value': averageValue,
      'min_value': minValue,
      'max_value': maxValue,
      'sample_count': sampleCount,
      'last_update': lastUpdate.millisecondsSinceEpoch,
    };
  }
}

/// Performance snapshot for Firebase
class PerformanceSnapshot {
  final DateTime timestamp;
  final double fps;
  final double memoryUsageMB;
  final double networkLatencyMS;
  final bool isPerformanceGood;
  final int warningsCount;

  PerformanceSnapshot({
    required this.timestamp,
    required this.fps,
    required this.memoryUsageMB,
    required this.networkLatencyMS,
    required this.isPerformanceGood,
    required this.warningsCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'fps': fps,
      'memory_usage_mb': memoryUsageMB,
      'network_latency_ms': networkLatencyMS,
      'is_performance_good': isPerformanceGood,
      'warnings_count': warningsCount,
    };
  }
}

/// Battery snapshot for Firebase
class BatterySnapshot {
  final DateTime timestamp;
  final int batteryLevel;
  final BatteryState batteryState;
  final double powerConsumptionMA;
  final BatteryOptimizationMode optimizationMode;
  final bool isOptimizing;
  final int activeStrategiesCount;

  BatterySnapshot({
    required this.timestamp,
    required this.batteryLevel,
    required this.batteryState,
    required this.powerConsumptionMA,
    required this.optimizationMode,
    required this.isOptimizing,
    required this.activeStrategiesCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'battery_level': batteryLevel,
      'battery_state': batteryState.name,
      'power_consumption_ma': powerConsumptionMA,
      'optimization_mode': optimizationMode.name,
      'is_optimizing': isOptimizing,
      'active_strategies_count': activeStrategiesCount,
    };
  }
}

/// Performance summary
class PerformanceSummary {
  final double averageFPS;
  final double averageMemoryUsageMB;
  final double averageBatteryConsumptionMA;
  final int performanceSnapshotsCount;
  final int batterySnapshotsCount;
  final int customMetricsCount;
  final int activeTracesCount;
  final int activeHttpMetricsCount;
  final bool isCollectingMetrics;

  PerformanceSummary({
    required this.averageFPS,
    required this.averageMemoryUsageMB,
    required this.averageBatteryConsumptionMA,
    required this.performanceSnapshotsCount,
    required this.batterySnapshotsCount,
    required this.customMetricsCount,
    required this.activeTracesCount,
    required this.activeHttpMetricsCount,
    required this.isCollectingMetrics,
  });

  Map<String, dynamic> toJson() {
    return {
      'average_fps': averageFPS,
      'average_memory_usage_mb': averageMemoryUsageMB,
      'average_battery_consumption_ma': averageBatteryConsumptionMA,
      'performance_snapshots_count': performanceSnapshotsCount,
      'battery_snapshots_count': batterySnapshotsCount,
      'custom_metrics_count': customMetricsCount,
      'active_traces_count': activeTracesCount,
      'active_http_metrics_count': activeHttpMetricsCount,
      'is_collecting_metrics': isCollectingMetrics,
    };
  }
}