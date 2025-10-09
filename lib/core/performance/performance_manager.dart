import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:async';
import 'dart:math' as math;

/// Advanced Performance Monitoring and Optimization System
class PerformanceManager {
  static final PerformanceManager _instance = PerformanceManager._internal();
  factory PerformanceManager() => _instance;
  PerformanceManager._internal();

  // Performance metrics
  final List<Duration> _frameTimes = [];
  final List<double> _frameRates = [];
  final Map<String, Duration> _widgetBuildTimes = {};
  final Map<String, int> _widgetRebuildCounts = {};
  
  // Memory tracking
  int _maxMemoryUsage = 0;
  int _currentMemoryUsage = 0;
  final List<int> _memorySnapshots = [];
  
  // Performance thresholds
  static const Duration _frameTimeThreshold = Duration(milliseconds: 16); // 60fps
  static const Duration _slowFrameThreshold = Duration(milliseconds: 32); // 30fps
  static const int _maxFrameHistorySize = 300; // 5 seconds at 60fps
  static const int _memoryWarningThreshold = 150 * 1024 * 1024; // 150MB
  
  Timer? _performanceTimer;
  bool _isMonitoring = false;
  
  // Performance callbacks
  VoidCallback? _onSlowFrame;
  VoidCallback? _onMemoryWarning;
  Function(PerformanceStats)? _onPerformanceUpdate;

  /// Initialize performance monitoring
  void initialize({
    VoidCallback? onSlowFrame,
    VoidCallback? onMemoryWarning,
    Function(PerformanceStats)? onPerformanceUpdate,
  }) {
    _onSlowFrame = onSlowFrame;
    _onMemoryWarning = onMemoryWarning;
    _onPerformanceUpdate = onPerformanceUpdate;
    
    startMonitoring();
  }

  /// Start performance monitoring
  void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    // Monitor frame performance
    SchedulerBinding.instance.addPersistentFrameCallback(_onFrameEnd);
    
    // Monitor memory and performance metrics every second
    _performanceTimer = Timer.periodic(
      const Duration(seconds: 1),
      _performanceCheck,
    );
    
    if (kDebugMode) {
      debugPrint('Performance monitoring started');
    }
  }

  /// Stop performance monitoring
  void stopMonitoring() {
    if (!_isMonitoring) return;
    
    _isMonitoring = false;
    _performanceTimer?.cancel();
    SchedulerBinding.instance.removePersistentFrameCallback(_onFrameEnd);
    
    if (kDebugMode) {
      debugPrint('Performance monitoring stopped');
    }
  }

  /// Frame callback to measure frame times
  void _onFrameEnd(Duration timeStamp) {
    if (_frameTimes.isEmpty) {
      _frameTimes.add(timeStamp);
      return;
    }
    
    final lastFrameTime = _frameTimes.last;
    final frameDuration = timeStamp - lastFrameTime;
    
    _frameTimes.add(timeStamp);
    
    // Keep only recent frame times
    if (_frameTimes.length > _maxFrameHistorySize) {
      _frameTimes.removeAt(0);
    }
    
    // Calculate frame rate
    if (frameDuration.inMicroseconds > 0) {
      final frameRate = 1000000 / frameDuration.inMicroseconds;
      _frameRates.add(frameRate);
      
      if (_frameRates.length > _maxFrameHistorySize) {
        _frameRates.removeAt(0);
      }
    }
    
    // Check for slow frames
    if (frameDuration > _slowFrameThreshold) {
      _onSlowFrameDetected(frameDuration);
    }
  }

  /// Handle slow frame detection
  void _onSlowFrameDetected(Duration frameDuration) {
    if (kDebugMode) {
      debugPrint('Slow frame detected: ${frameDuration.inMilliseconds}ms');
    }
    
    _onSlowFrame?.call();
  }

  /// Periodic performance check
  void _performanceCheck(Timer timer) {
    _checkMemoryUsage();
    _reportPerformanceStats();
  }

  /// Check memory usage
  void _checkMemoryUsage() {
    // Note: In a real implementation, you would use platform-specific
    // memory monitoring. This is a simplified version.
    
    // Simulate memory usage tracking
    _currentMemoryUsage = _estimateMemoryUsage();
    _memorySnapshots.add(_currentMemoryUsage);
    
    if (_memorySnapshots.length > 60) { // Keep 1 minute of history
      _memorySnapshots.removeAt(0);
    }
    
    if (_currentMemoryUsage > _maxMemoryUsage) {
      _maxMemoryUsage = _currentMemoryUsage;
    }
    
    if (_currentMemoryUsage > _memoryWarningThreshold) {
      _onMemoryWarning?.call();
    }
  }

  /// Estimate memory usage (simplified)
  int _estimateMemoryUsage() {
    // This is a simplified estimation
    // In a real app, you'd use platform channels to get actual memory usage
    return 50 * 1024 * 1024 + (math.Random().nextInt(20) * 1024 * 1024);
  }

  /// Report performance statistics
  void _reportPerformanceStats() {
    final stats = getPerformanceStats();
    _onPerformanceUpdate?.call(stats);
    
    if (kDebugMode && stats.averageFrameRate < 50) {
      debugPrint('Performance warning: Low frame rate (${stats.averageFrameRate.toStringAsFixed(1)} fps)');
    }
  }

  /// Track widget build time
  void trackWidgetBuild(String widgetName, Duration buildTime) {
    _widgetBuildTimes[widgetName] = buildTime;
    _widgetRebuildCounts[widgetName] = (_widgetRebuildCounts[widgetName] ?? 0) + 1;
    
    if (kDebugMode && buildTime.inMilliseconds > 10) {
      debugPrint('Slow widget build: $widgetName took ${buildTime.inMilliseconds}ms');
    }
  }

  /// Get current performance statistics
  PerformanceStats getPerformanceStats() {
    return PerformanceStats(
      averageFrameRate: _calculateAverageFrameRate(),
      frameTimeP95: _calculateFrameTimePercentile(0.95),
      frameTimeP99: _calculateFrameTimePercentile(0.99),
      slowFrameCount: _countSlowFrames(),
      currentMemoryUsage: _currentMemoryUsage,
      maxMemoryUsage: _maxMemoryUsage,
      averageMemoryUsage: _calculateAverageMemoryUsage(),
      totalWidgetRebuilds: _widgetRebuildCounts.values.fold(0, (a, b) => a + b),
      slowWidgetBuilds: _getSlowWidgetBuilds(),
    );
  }

  /// Calculate average frame rate
  double _calculateAverageFrameRate() {
    if (_frameRates.isEmpty) return 0.0;
    
    final sum = _frameRates.fold(0.0, (a, b) => a + b);
    return sum / _frameRates.length;
  }

  /// Calculate frame time percentile
  Duration _calculateFrameTimePercentile(double percentile) {
    if (_frameTimes.length < 2) return Duration.zero;
    
    final durations = <Duration>[];
    for (int i = 1; i < _frameTimes.length; i++) {
      durations.add(_frameTimes[i] - _frameTimes[i - 1]);
    }
    
    durations.sort((a, b) => a.compareTo(b));
    final index = ((durations.length - 1) * percentile).round();
    return durations[index];
  }

  /// Count slow frames
  int _countSlowFrames() {
    int count = 0;
    for (int i = 1; i < _frameTimes.length; i++) {
      final frameDuration = _frameTimes[i] - _frameTimes[i - 1];
      if (frameDuration > _slowFrameThreshold) {
        count++;
      }
    }
    return count;
  }

  /// Calculate average memory usage
  double _calculateAverageMemoryUsage() {
    if (_memorySnapshots.isEmpty) return 0.0;
    
    final sum = _memorySnapshots.fold(0, (a, b) => a + b);
    return sum / _memorySnapshots.length;
  }

  /// Get list of slow widget builds
  List<SlowWidgetBuild> _getSlowWidgetBuilds() {
    return _widgetBuildTimes.entries
        .where((entry) => entry.value.inMilliseconds > 5)
        .map((entry) => SlowWidgetBuild(
              widgetName: entry.key,
              buildTime: entry.value,
              rebuildCount: _widgetRebuildCounts[entry.key] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.buildTime.compareTo(a.buildTime));
  }

  /// Clear performance history
  void clearHistory() {
    _frameTimes.clear();
    _frameRates.clear();
    _memorySnapshots.clear();
    _widgetBuildTimes.clear();
    _widgetRebuildCounts.clear();
    _maxMemoryUsage = 0;
  }

  /// Generate performance report
  String generateReport() {
    final stats = getPerformanceStats();
    
    return '''
Performance Report
==================
Frame Rate: ${stats.averageFrameRate.toStringAsFixed(1)} fps
95th Percentile Frame Time: ${stats.frameTimeP95.inMilliseconds}ms
99th Percentile Frame Time: ${stats.frameTimeP99.inMilliseconds}ms
Slow Frames: ${stats.slowFrameCount}
Current Memory: ${(stats.currentMemoryUsage / 1024 / 1024).toStringAsFixed(1)} MB
Max Memory: ${(stats.maxMemoryUsage / 1024 / 1024).toStringAsFixed(1)} MB
Average Memory: ${(stats.averageMemoryUsage / 1024 / 1024).toStringAsFixed(1)} MB
Total Widget Rebuilds: ${stats.totalWidgetRebuilds}
Slow Widget Builds: ${stats.slowWidgetBuilds.length}

Top Slow Widgets:
${stats.slowWidgetBuilds.take(5).map((w) => '${w.widgetName}: ${w.buildTime.inMilliseconds}ms (${w.rebuildCount} rebuilds)').join('\n')}
''';
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    clearHistory();
  }
}

/// Performance statistics data class
class PerformanceStats {
  const PerformanceStats({
    required this.averageFrameRate,
    required this.frameTimeP95,
    required this.frameTimeP99,
    required this.slowFrameCount,
    required this.currentMemoryUsage,
    required this.maxMemoryUsage,
    required this.averageMemoryUsage,
    required this.totalWidgetRebuilds,
    required this.slowWidgetBuilds,
  });

  final double averageFrameRate;
  final Duration frameTimeP95;
  final Duration frameTimeP99;
  final int slowFrameCount;
  final int currentMemoryUsage;
  final int maxMemoryUsage;
  final double averageMemoryUsage;
  final int totalWidgetRebuilds;
  final List<SlowWidgetBuild> slowWidgetBuilds;

  /// Check if performance is good
  bool get isPerformanceGood =>
      averageFrameRate >= 55 &&
      frameTimeP95.inMilliseconds <= 20 &&
      currentMemoryUsage < 100 * 1024 * 1024; // 100MB

  /// Check if performance is poor
  bool get isPerformancePoor =>
      averageFrameRate < 45 ||
      frameTimeP95.inMilliseconds > 30 ||
      currentMemoryUsage > 200 * 1024 * 1024; // 200MB
}

/// Slow widget build information
class SlowWidgetBuild {
  const SlowWidgetBuild({
    required this.widgetName,
    required this.buildTime,
    required this.rebuildCount,
  });

  final String widgetName;
  final Duration buildTime;
  final int rebuildCount;
}

/// Widget for tracking build performance
class PerformanceTracker extends StatelessWidget {
  const PerformanceTracker({
    super.key,
    required this.child,
    required this.name,
  });

  final Widget child;
  final String name;

  @override
  Widget build(BuildContext context) {
    final stopwatch = Stopwatch()..start();
    
    return Builder(
      builder: (context) {
        final widget = child;
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          stopwatch.stop();
          PerformanceManager().trackWidgetBuild(name, stopwatch.elapsed);
        });
        
        return widget;
      },
    );
  }
}

/// Performance optimization utilities
class PerformanceUtils {
  PerformanceUtils._();

  /// Debounce function calls
  static Timer? _debounceTimer;
  static void debounce(Duration delay, VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }

  /// Throttle function calls
  static DateTime? _lastThrottle;
  static void throttle(Duration interval, VoidCallback callback) {
    final now = DateTime.now();
    if (_lastThrottle == null || now.difference(_lastThrottle!) >= interval) {
      _lastThrottle = now;
      callback();
    }
  }

  /// Lazy load images
  static bool shouldLoadImage(BuildContext context, double threshold) {
    // Implementation would check if widget is visible in viewport
    return true; // Simplified
  }

  /// Check if widget is in viewport
  static bool isWidgetVisible(BuildContext context) {
    final renderObject = context.findRenderObject();
    if (renderObject == null) return false;
    
    final viewport = RenderAbstractViewport.of(renderObject);
    if (viewport == null) return true;
    
    final vpRange = viewport.getVisibleRange();
    final targetRange = viewport.showOnScreen(renderObject);
    
    return vpRange.start <= targetRange.start && targetRange.end <= vpRange.end;
  }

  /// Optimize list performance
  static Widget buildOptimizedList({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    double? itemExtent,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
  }) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      itemExtent: itemExtent,
      addAutomaticKeepAlives: addAutomaticKeepAlives,
      addRepaintBoundaries: addRepaintBoundaries,
      physics: const ClampingScrollPhysics(),
    );
  }
}