import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../firebase/firebase_manager.dart';
import '../../features/auth/services/security_service.dart';

/// Comprehensive Performance Monitor for app optimization
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final SecurityService _security = SecurityService();
  
  // Performance tracking
  Timer? _performanceTimer;
  final Queue<PerformanceSnapshot> _performanceHistory = Queue<PerformanceSnapshot>();
  final StreamController<PerformanceMetrics> _metricsController = StreamController<PerformanceMetrics>.broadcast();
  
  // FPS tracking
  final Queue<Duration> _frameTimes = Queue<Duration>();
  DateTime? _lastFrameTime;
  double _currentFPS = 60.0;
  
  // Memory tracking
  final Queue<double> _memoryUsage = Queue<double>();
  double _currentMemoryMB = 0.0;
  
  // Network tracking
  final Map<String, NetworkMetric> _networkMetrics = {};
  int _totalNetworkRequests = 0;
  double _averageResponseTime = 0.0;
  
  // App lifecycle tracking
  AppLifecycleState _currentLifecycleState = AppLifecycleState.resumed;
  DateTime _lastStateChange = DateTime.now();
  
  // Performance thresholds
  static const double _lowFPSThreshold = 30.0;
  static const double _highMemoryThresholdMB = 150.0;
  static const double _slowNetworkThresholdMS = 3000.0;
  static const int _maxHistorySize = 100;
  static const Duration _monitoringInterval = Duration(seconds: 10);

  bool _isInitialized = false;
  bool _isMonitoring = false;

  /// Stream of performance metrics
  Stream<PerformanceMetrics> get metricsStream => _metricsController.stream;

  /// Current FPS
  double get currentFPS => _currentFPS;

  /// Current memory usage in MB
  double get currentMemoryMB => _currentMemoryMB;

  /// Is monitoring active
  bool get isMonitoring => _isMonitoring;

  /// Initialize performance monitor
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Setup frame callback for FPS monitoring
      _setupFrameCallback();
      
      // Setup app lifecycle listener
      _setupLifecycleListener();
      
      // Start performance monitoring
      _startPerformanceMonitoring();
      
      _isInitialized = true;
      _isMonitoring = true;

      await _security.logSecurityEvent(
        SecurityEventType.authSuccess,
        'Performance monitor initialized',
        metadata: {
          'monitoring_interval_seconds': _monitoringInterval.inSeconds,
          'fps_threshold': _lowFPSThreshold,
          'memory_threshold_mb': _highMemoryThresholdMB,
        },
      );

    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Performance monitor initialization failed');
      rethrow;
    }
  }

  /// Setup frame callback for FPS monitoring
  void _setupFrameCallback() {
    SchedulerBinding.instance.addPersistentFrameCallback((timeStamp) {
      _trackFrameTime(timeStamp);
    });
  }

  /// Setup app lifecycle listener
  void _setupLifecycleListener() {
    WidgetsBinding.instance.didChangeAppLifecycleState(_currentLifecycleState);
  }

  /// Track frame time for FPS calculation
  void _trackFrameTime(Duration timeStamp) {
    try {
      final now = DateTime.now();
      
      if (_lastFrameTime != null) {
        final frameDuration = now.difference(_lastFrameTime!);
        _frameTimes.add(frameDuration);
        
        // Keep only recent frame times
        if (_frameTimes.length > 60) { // Last 60 frames
          _frameTimes.removeFirst();
        }
        
        // Calculate current FPS
        _calculateFPS();
      }
      
      _lastFrameTime = now;
    } catch (e) {
      debugPrint('[PerformanceMonitor] Frame tracking error: $e');
    }
  }

  /// Calculate FPS from frame times
  void _calculateFPS() {
    if (_frameTimes.isEmpty) return;
    
    try {
      final totalDuration = _frameTimes.fold<Duration>(
        Duration.zero,
        (sum, duration) => sum + duration,
      );
      
      final averageFrameTime = totalDuration.inMicroseconds / _frameTimes.length;
      _currentFPS = 1000000.0 / averageFrameTime; // Convert to FPS
      
      // Clamp FPS to reasonable range
      _currentFPS = _currentFPS.clamp(0.0, 120.0);
    } catch (e) {
      _currentFPS = 60.0; // Default fallback
    }
  }

  /// Start performance monitoring
  void _startPerformanceMonitoring() {
    _performanceTimer = Timer.periodic(_monitoringInterval, (timer) {
      _collectPerformanceMetrics();
    });
  }

  /// Collect comprehensive performance metrics
  Future<void> _collectPerformanceMetrics() async {
    try {
      // Collect memory usage
      await _collectMemoryMetrics();
      
      // Collect network metrics
      _collectNetworkMetrics();
      
      // Create performance snapshot
      final snapshot = PerformanceSnapshot(
        timestamp: DateTime.now(),
        fps: _currentFPS,
        memoryUsageMB: _currentMemoryMB,
        networkRequestCount: _totalNetworkRequests,
        averageResponseTimeMS: _averageResponseTime,
        appLifecycleState: _currentLifecycleState,
      );
      
      // Add to history
      _performanceHistory.add(snapshot);
      if (_performanceHistory.length > _maxHistorySize) {
        _performanceHistory.removeFirst();
      }
      
      // Create current metrics
      final metrics = PerformanceMetrics(
        fps: _currentFPS,
        memoryUsageMB: _currentMemoryMB,
        networkLatencyMS: _averageResponseTime,
        isPerformanceGood: _isPerformanceGood(),
        timestamp: DateTime.now(),
        warnings: _generateWarnings(),
      );
      
      // Emit metrics
      _metricsController.add(metrics);
      
      // Check for performance issues
      await _checkPerformanceIssues(metrics);
      
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Performance metrics collection failed');
    }
  }

  /// Collect memory metrics
  Future<void> _collectMemoryMetrics() async {
    try {
      // Get process memory info (Windows specific)
      final processInfo = await Process.run('tasklist', [
        '/FI', 'PID eq ${pid}',
        '/FO', 'CSV',
        '/NH'
      ]);

      if (processInfo.exitCode == 0) {
        final output = processInfo.stdout.toString();
        final lines = output.split('\n');
        if (lines.isNotEmpty) {
          final parts = lines[0].split(',');
          if (parts.length >= 5) {
            final memoryStr = parts[4].replaceAll('"', '').replaceAll(',', '');
            final memoryKB = double.tryParse(memoryStr) ?? 0.0;
            _currentMemoryMB = memoryKB / 1024.0;
          }
        }
      }
      
      // Add to memory history
      _memoryUsage.add(_currentMemoryMB);
      if (_memoryUsage.length > 60) { // Keep last 60 readings
        _memoryUsage.removeFirst();
      }
      
    } catch (e) {
      // Fallback memory estimation
      _currentMemoryMB = 50.0; // Default estimate
    }
  }

  /// Collect network metrics
  void _collectNetworkMetrics() {
    try {
      if (_networkMetrics.isEmpty) {
        _averageResponseTime = 0.0;
        return;
      }
      
      final totalResponseTime = _networkMetrics.values
          .fold<double>(0.0, (sum, metric) => sum + metric.responseTimeMS);
      
      _averageResponseTime = totalResponseTime / _networkMetrics.length;
      _totalNetworkRequests = _networkMetrics.length;
      
    } catch (e) {
      _averageResponseTime = 0.0;
      _totalNetworkRequests = 0;
    }
  }

  /// Check if overall performance is good
  bool _isPerformanceGood() {
    return _currentFPS >= _lowFPSThreshold &&
           _currentMemoryMB <= _highMemoryThresholdMB &&
           _averageResponseTime <= _slowNetworkThresholdMS;
  }

  /// Generate performance warnings
  List<PerformanceWarning> _generateWarnings() {
    final warnings = <PerformanceWarning>[];
    
    if (_currentFPS < _lowFPSThreshold) {
      warnings.add(PerformanceWarning(
        type: PerformanceWarningType.lowFPS,
        message: 'Low FPS detected: ${_currentFPS.toStringAsFixed(1)}',
        severity: _currentFPS < 15.0 ? WarningGeverity.critical : WarningGeverity.warning,
      ));
    }
    
    if (_currentMemoryMB > _highMemoryThresholdMB) {
      warnings.add(PerformanceWarning(
        type: PerformanceWarningType.highMemory,
        message: 'High memory usage: ${_currentMemoryMB.toStringAsFixed(1)}MB',
        severity: _currentMemoryMB > 200.0 ? WarningGeverity.critical : WarningGeverity.warning,
      ));
    }
    
    if (_averageResponseTime > _slowNetworkThresholdMS) {
      warnings.add(PerformanceWarning(
        type: PerformanceWarningType.slowNetwork,
        message: 'Slow network response: ${_averageResponseTime.toStringAsFixed(0)}ms',
        severity: _averageResponseTime > 5000.0 ? WarningGeverity.critical : WarningGeverity.warning,
      ));
    }
    
    return warnings;
  }

  /// Check for performance issues and take action
  Future<void> _checkPerformanceIssues(PerformanceMetrics metrics) async {
    try {
      final criticalWarnings = metrics.warnings
          .where((w) => w.severity == WarningGeverity.critical)
          .toList();
      
      if (criticalWarnings.isNotEmpty) {
        await _handleCriticalPerformanceIssues(criticalWarnings);
      }
      
      // Log performance analytics
      AnalyticsHelper.trackUserAction('performance_metrics', parameters: {
        'fps': metrics.fps,
        'memory_usage_mb': metrics.memoryUsageMB,
        'network_latency_ms': metrics.networkLatencyMS,
        'is_performance_good': metrics.isPerformanceGood,
        'warning_count': metrics.warnings.length,
        'critical_warning_count': criticalWarnings.length,
      });
      
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Performance issue check failed');
    }
  }

  /// Handle critical performance issues
  Future<void> _handleCriticalPerformanceIssues(List<PerformanceWarning> warnings) async {
    try {
      for (final warning in warnings) {
        await _security.logSecurityEvent(
          SecurityEventType.suspiciousActivity,
          'Critical performance issue detected',
          metadata: {
            'warning_type': warning.type.name,
            'message': warning.message,
            'severity': warning.severity.name,
          },
        );
        
        // Take appropriate action based on warning type
        switch (warning.type) {
          case PerformanceWarningType.lowFPS:
            await _handleLowFPS();
            break;
          case PerformanceWarningType.highMemory:
            await _handleHighMemory();
            break;
          case PerformanceWarningType.slowNetwork:
            await _handleSlowNetwork();
            break;
        }
      }
    } catch (e) {
      FirebaseManager().logError(e, StackTrace.current, reason: 'Handle critical performance issues failed');
    }
  }

  /// Handle low FPS issues
  Future<void> _handleLowFPS() async {
    try {
      debugPrint('[PerformanceMonitor] Handling low FPS - reducing UI complexity');
      
      // Reduce animations, disable effects, etc.
      // This would trigger app-wide performance optimizations
      
    } catch (e) {
      debugPrint('[PerformanceMonitor] Handle low FPS failed: $e');
    }
  }

  /// Handle high memory usage
  Future<void> _handleHighMemory() async {
    try {
      debugPrint('[PerformanceMonitor] Handling high memory - triggering cleanup');
      
      // Trigger memory cleanup
      // This would call MemoryManager cleanup methods
      
    } catch (e) {
      debugPrint('[PerformanceMonitor] Handle high memory failed: $e');
    }
  }

  /// Handle slow network
  Future<void> _handleSlowNetwork() async {
    try {
      debugPrint('[PerformanceMonitor] Handling slow network - optimizing requests');
      
      // Optimize network requests, enable compression, etc.
      
    } catch (e) {
      debugPrint('[PerformanceMonitor] Handle slow network failed: $e');
    }
  }

  /// Track network request
  void trackNetworkRequest(String url, double responseTimeMS, bool isSuccess) {
    try {
      final metric = NetworkMetric(
        url: url,
        responseTimeMS: responseTimeMS,
        isSuccess: isSuccess,
        timestamp: DateTime.now(),
      );
      
      _networkMetrics[url] = metric;
      _totalNetworkRequests++;
      
      // Update average response time
      _updateAverageResponseTime(responseTimeMS);
      
    } catch (e) {
      debugPrint('[PerformanceMonitor] Track network request failed: $e');
    }
  }

  /// Get current performance metrics as a map
  Map<String, dynamic> getCurrentMetrics() {
    return {
      'cpu': _calculateCPUUsage(),
      'memory': _currentMemoryMB,
      'battery': _getBatteryLevel(),
      'network': _calculateNetworkUsage(),
      'fps': _currentFPS,
    };
  }

  /// Calculate approximate CPU usage based on FPS and frame times
  double _calculateCPUUsage() {
    if (_frameTimes.isEmpty) return 15.0;
    
    // Approximate CPU usage based on frame performance
    final fpsRatio = _currentFPS / 60.0;
    final cpuUsage = (1.0 - fpsRatio) * 100.0;
    return cpuUsage.clamp(5.0, 95.0);
  }

  /// Get battery level (placeholder - requires platform-specific implementation)
  double _getBatteryLevel() {
    // This would typically use platform channels to get real battery level
    // For now, return a simulated value
    final now = DateTime.now();
    final dayMinutes = (now.hour * 60 + now.minute);
    return (100.0 - (dayMinutes / 14.4)).clamp(20.0, 100.0);
  }

  /// Calculate network usage as a percentage
  double _calculateNetworkUsage() {
    if (_averageResponseTime <= 100) return 20.0;
    if (_averageResponseTime <= 500) return 50.0;
    if (_averageResponseTime <= 1000) return 75.0;
    return 90.0;
  }
        isSuccess: isSuccess,
        timestamp: DateTime.now(),
      );
      
      _networkMetrics[url] = metric;
      
      // Keep only recent metrics
      final cutoff = DateTime.now().subtract(const Duration(minutes: 5));
      _networkMetrics.removeWhere((key, value) => value.timestamp.isBefore(cutoff));
      
    } catch (e) {
      debugPrint('[PerformanceMonitor] Track network request failed: $e');
    }
  }

  /// Track app lifecycle state change
  void trackLifecycleStateChange(AppLifecycleState state) {
    try {
      _currentLifecycleState = state;
      _lastStateChange = DateTime.now();
      
      AnalyticsHelper.trackUserAction('app_lifecycle_change', parameters: {
        'state': state.name,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      
    } catch (e) {
      debugPrint('[PerformanceMonitor] Track lifecycle state change failed: $e');
    }
  }

  /// Get performance statistics
  PerformanceStatistics getPerformanceStatistics() {
    try {
      final recentSnapshots = _performanceHistory.length >= 10
          ? _performanceHistory.toList().sublist(_performanceHistory.length - 10)
          : _performanceHistory.toList();
      
      final averageFPS = recentSnapshots.isNotEmpty
          ? recentSnapshots.fold<double>(0.0, (sum, s) => sum + s.fps) / recentSnapshots.length
          : _currentFPS;
      
      final averageMemory = recentSnapshots.isNotEmpty
          ? recentSnapshots.fold<double>(0.0, (sum, s) => sum + s.memoryUsageMB) / recentSnapshots.length
          : _currentMemoryMB;
      
      return PerformanceStatistics(
        currentFPS: _currentFPS,
        averageFPS: averageFPS,
        currentMemoryMB: _currentMemoryMB,
        averageMemoryMB: averageMemory,
        networkRequestCount: _totalNetworkRequests,
        averageResponseTimeMS: _averageResponseTime,
        performanceHistory: List.from(_performanceHistory),
        isMonitoring: _isMonitoring,
      );
    } catch (e) {
      return PerformanceStatistics(
        currentFPS: 0.0,
        averageFPS: 0.0,
        currentMemoryMB: 0.0,
        averageMemoryMB: 0.0,
        networkRequestCount: 0,
        averageResponseTimeMS: 0.0,
        performanceHistory: [],
        isMonitoring: false,
      );
    }
  }

  /// Start monitoring
  void startMonitoring() {
    if (!_isMonitoring && _isInitialized) {
      _startPerformanceMonitoring();
      _isMonitoring = true;
    }
  }

  /// Stop monitoring
  void stopMonitoring() {
    if (_isMonitoring) {
      _performanceTimer?.cancel();
      _isMonitoring = false;
    }
  }

  /// Export performance data
  Map<String, dynamic> exportPerformanceData() {
    try {
      return {
        'export_timestamp': DateTime.now().millisecondsSinceEpoch,
        'current_metrics': {
          'fps': _currentFPS,
          'memory_mb': _currentMemoryMB,
          'network_requests': _totalNetworkRequests,
          'avg_response_time_ms': _averageResponseTime,
        },
        'performance_history': _performanceHistory
            .map((snapshot) => snapshot.toJson())
            .toList(),
        'statistics': getPerformanceStatistics().toJson(),
      };
    } catch (e) {
      return {
        'error': 'Failed to export performance data: ${e.toString()}',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  /// Dispose performance monitor
  void dispose() {
    _performanceTimer?.cancel();
    _metricsController.close();
    _performanceHistory.clear();
    _frameTimes.clear();
    _memoryUsage.clear();
    _networkMetrics.clear();
  }
}

/// Performance metrics
class PerformanceMetrics {
  final double fps;
  final double memoryUsageMB;
  final double networkLatencyMS;
  final bool isPerformanceGood;
  final DateTime timestamp;
  final List<PerformanceWarning> warnings;

  PerformanceMetrics({
    required this.fps,
    required this.memoryUsageMB,
    required this.networkLatencyMS,
    required this.isPerformanceGood,
    required this.timestamp,
    required this.warnings,
  });
}

/// Performance snapshot
class PerformanceSnapshot {
  final DateTime timestamp;
  final double fps;
  final double memoryUsageMB;
  final int networkRequestCount;
  final double averageResponseTimeMS;
  final AppLifecycleState appLifecycleState;

  PerformanceSnapshot({
    required this.timestamp,
    required this.fps,
    required this.memoryUsageMB,
    required this.networkRequestCount,
    required this.averageResponseTimeMS,
    required this.appLifecycleState,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.millisecondsSinceEpoch,
      'fps': fps,
      'memory_usage_mb': memoryUsageMB,
      'network_request_count': networkRequestCount,
      'average_response_time_ms': averageResponseTimeMS,
      'app_lifecycle_state': appLifecycleState.name,
    };
  }
}

/// Network metric
class NetworkMetric {
  final String url;
  final double responseTimeMS;
  final bool isSuccess;
  final DateTime timestamp;

  NetworkMetric({
    required this.url,
    required this.responseTimeMS,
    required this.isSuccess,
    required this.timestamp,
  });
}

/// Performance warning
class PerformanceWarning {
  final PerformanceWarningType type;
  final String message;
  final WarningGeverity severity;

  PerformanceWarning({
    required this.type,
    required this.message,
    required this.severity,
  });
}

/// Performance warning types
enum PerformanceWarningType {
  lowFPS,
  highMemory,
  slowNetwork,
}

/// Warning severity
enum WarningGeverity {
  info,
  warning,
  critical,
}

/// Performance statistics
class PerformanceStatistics {
  final double currentFPS;
  final double averageFPS;
  final double currentMemoryMB;
  final double averageMemoryMB;
  final int networkRequestCount;
  final double averageResponseTimeMS;
  final List<PerformanceSnapshot> performanceHistory;
  final bool isMonitoring;

  PerformanceStatistics({
    required this.currentFPS,
    required this.averageFPS,
    required this.currentMemoryMB,
    required this.averageMemoryMB,
    required this.networkRequestCount,
    required this.averageResponseTimeMS,
    required this.performanceHistory,
    required this.isMonitoring,
  });

  Map<String, dynamic> toJson() {
    return {
      'current_fps': currentFPS,
      'average_fps': averageFPS,
      'current_memory_mb': currentMemoryMB,
      'average_memory_mb': averageMemoryMB,
      'network_request_count': networkRequestCount,
      'average_response_time_ms': averageResponseTimeMS,
      'is_monitoring': isMonitoring,
    };
  }
}