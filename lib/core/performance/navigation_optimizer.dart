import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../performance/memory_manager.dart';
import '../performance/animation_optimizer.dart';

/// Advanced Navigation Optimization and Management System
class NavigationOptimizer {
  static final NavigationOptimizer _instance = NavigationOptimizer._internal();
  factory NavigationOptimizer() => _instance;
  NavigationOptimizer._internal();

  // Navigation state
  final Map<String, Route> _routeCache = {};
  final Map<String, Widget> _pageCache = {};
  final List<String> _navigationHistory = [];
  
  // Performance settings
  bool _enableTransitions = true;
  bool _enableRouteCache = true;
  bool _enablePageCache = true;
  int _maxCacheSize = 10;
  
  // Navigation analytics
  final Map<String, int> _routeVisitCount = {};
  final Map<String, Duration> _routeBuildTimes = {};
  
  // Preloading
  final Set<String> _preloadedRoutes = {};
  final Map<String, Completer<Widget>> _preloadingRoutes = {};

  /// Initialize navigation optimizer
  void initialize() {
    _loadSettings();
  }

  /// Load optimizer settings
  void _loadSettings() {
    // In a real implementation, load from shared preferences
    _enableTransitions = true;
    _enableRouteCache = true;
    _enablePageCache = true;
    _maxCacheSize = 10;
  }

  /// Create optimized page route
  PageRoute<T> createOptimizedRoute<T extends Object?>({
    required Widget page,
    required String routeName,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
    Widget Function(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    )? transitionBuilder,
  }) {
    // Track route visit
    _trackRouteVisit(routeName);

    // Check cache first
    if (_enableRouteCache && _routeCache.containsKey(routeName)) {
      final cachedRoute = _routeCache[routeName] as PageRoute<T>;
      return cachedRoute;
    }

    // Create optimized page
    Widget optimizedPage = page;
    
    if (_enablePageCache) {
      optimizedPage = _CachedPageWrapper(
        routeName: routeName,
        child: page,
      );
    }

    // Create route with optimizations
    final route = _OptimizedPageRoute<T>(
      page: optimizedPage,
      routeName: routeName,
      settings: settings,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
      transitionDuration: _getOptimizedTransitionDuration(transitionDuration),
      reverseTransitionDuration: _getOptimizedTransitionDuration(reverseTransitionDuration),
      transitionBuilder: transitionBuilder ?? _getOptimizedTransition(),
    );

    // Cache route if enabled
    if (_enableRouteCache) {
      _cacheRoute(routeName, route);
    }

    return route;
  }

  /// Create optimized modal route
  Route<T> createOptimizedModalRoute<T extends Object?>({
    required WidgetBuilder builder,
    required String routeName,
    RouteSettings? settings,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
    Widget Function(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    )? transitionBuilder,
  }) {
    _trackRouteVisit(routeName);

    return _OptimizedModalRoute<T>(
      builder: builder,
      routeName: routeName,
      settings: settings,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor ?? Colors.black54,
      barrierLabel: barrierLabel,
      transitionDuration: _getOptimizedTransitionDuration(transitionDuration),
      reverseTransitionDuration: _getOptimizedTransitionDuration(reverseTransitionDuration),
      transitionBuilder: transitionBuilder ?? _getOptimizedModalTransition(),
    );
  }

  /// Preload route for faster navigation
  Future<void> preloadRoute(String routeName, WidgetBuilder builder) async {
    if (_preloadedRoutes.contains(routeName) || _preloadingRoutes.containsKey(routeName)) {
      return;
    }

    final completer = Completer<Widget>();
    _preloadingRoutes[routeName] = completer;

    try {
      // Build widget in background
      final widget = await _buildWidgetInBackground(builder);
      
      if (_enablePageCache) {
        _pageCache[routeName] = widget;
      }
      
      _preloadedRoutes.add(routeName);
      completer.complete(widget);
    } catch (error) {
      completer.completeError(error);
    } finally {
      _preloadingRoutes.remove(routeName);
    }
  }

  /// Build widget in background
  Future<Widget> _buildWidgetInBackground(WidgetBuilder builder) async {
    // Use a minimal context for building
    final context = _MinimalBuildContext();
    return builder(context);
  }

  /// Get optimized transition duration
  Duration _getOptimizedTransitionDuration(Duration? duration) {
    if (!_enableTransitions) {
      return Duration.zero;
    }
    
    if (duration == null) {
      return AnimationOptimizer().shouldAnimate 
          ? const Duration(milliseconds: 300)
          : Duration.zero;
    }
    
    return duration;
  }

  /// Get optimized page transition
  Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) _getOptimizedTransition() {
    if (!_enableTransitions || !AnimationOptimizer().shouldAnimate) {
      return (context, animation, secondaryAnimation, child) => child;
    }

    return (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        )),
        child: child,
      );
    };
  }

  /// Get optimized modal transition
  Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) _getOptimizedModalTransition() {
    if (!_enableTransitions || !AnimationOptimizer().shouldAnimate) {
      return (context, animation, secondaryAnimation, child) => child;
    }

    return (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.8,
            end: 1.0,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuart,
          )),
          child: child,
        ),
      );
    };
  }

  /// Cache route
  void _cacheRoute(String routeName, Route route) {
    _routeCache[routeName] = route;
    
    // Enforce cache size limit
    if (_routeCache.length > _maxCacheSize) {
      final oldestRoute = _routeCache.keys.first;
      _routeCache.remove(oldestRoute);
    }
  }

  /// Track route visit
  void _trackRouteVisit(String routeName) {
    _routeVisitCount[routeName] = (_routeVisitCount[routeName] ?? 0) + 1;
    _navigationHistory.add(routeName);
    
    // Keep limited history
    if (_navigationHistory.length > 100) {
      _navigationHistory.removeAt(0);
    }
  }

  /// Track route build time
  void trackRouteBuildTime(String routeName, Duration buildTime) {
    _routeBuildTimes[routeName] = buildTime;
  }

  /// Get navigation analytics
  NavigationAnalytics getAnalytics() {
    return NavigationAnalytics(
      routeVisitCount: Map.unmodifiable(_routeVisitCount),
      routeBuildTimes: Map.unmodifiable(_routeBuildTimes),
      navigationHistory: List.unmodifiable(_navigationHistory),
      cachedRoutes: _routeCache.length,
      cachedPages: _pageCache.length,
      preloadedRoutes: _preloadedRoutes.length,
    );
  }

  /// Clear caches
  void clearCaches() {
    _routeCache.clear();
    _pageCache.clear();
    _preloadedRoutes.clear();
    _preloadingRoutes.clear();
  }

  /// Set optimization settings
  void setSettings({
    bool? enableTransitions,
    bool? enableRouteCache,
    bool? enablePageCache,
    int? maxCacheSize,
  }) {
    _enableTransitions = enableTransitions ?? _enableTransitions;
    _enableRouteCache = enableRouteCache ?? _enableRouteCache;
    _enablePageCache = enablePageCache ?? _enablePageCache;
    _maxCacheSize = maxCacheSize ?? _maxCacheSize;
  }

  /// Dispose resources
  void dispose() {
    clearCaches();
    _routeVisitCount.clear();
    _routeBuildTimes.clear();
    _navigationHistory.clear();
  }
}

/// Navigation analytics data
class NavigationAnalytics {
  const NavigationAnalytics({
    required this.routeVisitCount,
    required this.routeBuildTimes,
    required this.navigationHistory,
    required this.cachedRoutes,
    required this.cachedPages,
    required this.preloadedRoutes,
  });

  final Map<String, int> routeVisitCount;
  final Map<String, Duration> routeBuildTimes;
  final List<String> navigationHistory;
  final int cachedRoutes;
  final int cachedPages;
  final int preloadedRoutes;

  /// Get most visited routes
  List<MapEntry<String, int>> getMostVisitedRoutes({int limit = 10}) {
    final entries = routeVisitCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }

  /// Get slowest building routes
  List<MapEntry<String, Duration>> getSlowestRoutes({int limit = 10}) {
    final entries = routeBuildTimes.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).toList();
  }
}

/// Optimized page route implementation
class _OptimizedPageRoute<T> extends PageRoute<T> {
  _OptimizedPageRoute({
    required this.page,
    required this.routeName,
    super.settings,
    this.maintainState = true,
    this.fullscreenDialog = false,
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
    this.transitionBuilder,
  })  : _transitionDuration = transitionDuration ?? const Duration(milliseconds: 300),
        _reverseTransitionDuration = reverseTransitionDuration;

  final Widget page;
  final String routeName;
  final Duration _transitionDuration;
  final Duration? _reverseTransitionDuration;
  final Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  )? transitionBuilder;

  @override
  final bool maintainState;

  @override
  final bool fullscreenDialog;

  @override
  Duration get transitionDuration => _transitionDuration;

  @override
  Duration get reverseTransitionDuration => _reverseTransitionDuration ?? _transitionDuration;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final stopwatch = Stopwatch()..start();
    
    final result = RepaintBoundary(
      child: page,
    );
    
    stopwatch.stop();
    NavigationOptimizer().trackRouteBuildTime(routeName, stopwatch.elapsed);
    
    return result;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (transitionBuilder != null) {
      return transitionBuilder!(context, animation, secondaryAnimation, child);
    }
    
    return child;
  }
}

/// Optimized modal route implementation
class _OptimizedModalRoute<T> extends ModalRoute<T> {
  _OptimizedModalRoute({
    required this.builder,
    required this.routeName,
    super.settings,
    this.barrierDismissible = true,
    this.barrierColor = Colors.black54,
    this.barrierLabel,
    Duration? transitionDuration,
    Duration? reverseTransitionDuration,
    this.transitionBuilder,
  })  : _transitionDuration = transitionDuration ?? const Duration(milliseconds: 300),
        _reverseTransitionDuration = reverseTransitionDuration;

  final WidgetBuilder builder;
  final String routeName;
  final Duration _transitionDuration;
  final Duration? _reverseTransitionDuration;
  final Widget Function(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  )? transitionBuilder;

  @override
  final bool barrierDismissible;

  @override
  final Color? barrierColor;

  @override
  final String? barrierLabel;

  @override
  Duration get transitionDuration => _transitionDuration;

  @override
  Duration get reverseTransitionDuration => _reverseTransitionDuration ?? _transitionDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final stopwatch = Stopwatch()..start();
    
    final result = builder(context);
    
    stopwatch.stop();
    NavigationOptimizer().trackRouteBuildTime(routeName, stopwatch.elapsed);
    
    return result;
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (transitionBuilder != null) {
      return transitionBuilder!(context, animation, secondaryAnimation, child);
    }
    
    return child;
  }
}

/// Cached page wrapper
class _CachedPageWrapper extends StatefulWidget {
  const _CachedPageWrapper({
    required this.routeName,
    required this.child,
  });

  final String routeName;
  final Widget child;

  @override
  State<_CachedPageWrapper> createState() => _CachedPageWrapperState();
}

class _CachedPageWrapperState extends State<_CachedPageWrapper>
    with AutomaticKeepAliveStateMixin {
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

/// Minimal build context for background building
class _MinimalBuildContext implements BuildContext {
  @override
  bool get debugDoingBuild => false;

  @override
  InheritedWidget dependOnInheritedElement(InheritedElement ancestor, {Object? aspect}) {
    throw UnimplementedError();
  }

  @override
  T? dependOnInheritedWidgetOfExactType<T extends InheritedWidget>({Object? aspect}) {
    return null;
  }

  @override
  DiagnosticsNode describeElement(String name, {DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty}) {
    throw UnimplementedError();
  }

  @override
  List<DiagnosticsNode> describeMissingAncestor({required Type expectedAncestorType}) {
    throw UnimplementedError();
  }

  @override
  DiagnosticsNode describeOwnershipChain(String name) {
    throw UnimplementedError();
  }

  @override
  DiagnosticsNode describeWidget(String name, {DiagnosticsTreeStyle style = DiagnosticsTreeStyle.errorProperty}) {
    throw UnimplementedError();
  }

  @override
  T? findAncestorRenderObjectOfType<T extends RenderObject>() {
    return null;
  }

  @override
  T? findAncestorStateOfType<T extends State<StatefulWidget>>() {
    return null;
  }

  @override
  T? findAncestorWidgetOfExactType<T extends Widget>() {
    return null;
  }

  @override
  RenderObject? findRenderObject() {
    return null;
  }

  @override
  T? findRootAncestorStateOfType<T extends State<StatefulWidget>>() {
    return null;
  }

  @override
  InheritedElement? getElementForInheritedWidgetOfExactType<T extends InheritedWidget>() {
    return null;
  }

  @override
  BuildOwner? get owner => null;

  @override
  Size? get size => null;

  @override
  void visitAncestorElements(bool Function(Element element) visitor) {}

  @override
  void visitChildElements(ElementVisitor visitor) {}

  @override
  Widget get widget => const SizedBox();
  
  @override
  bool get mounted => false;
}

/// Navigation performance monitor
class NavigationPerformanceMonitor {
  static final NavigationPerformanceMonitor _instance = NavigationPerformanceMonitor._internal();
  factory NavigationPerformanceMonitor() => _instance;
  NavigationPerformanceMonitor._internal();

  final List<NavigationMetric> _metrics = [];
  Timer? _reportTimer;

  /// Start monitoring navigation performance
  void startMonitoring() {
    _reportTimer?.cancel();
    _reportTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _generateReport(),
    );
  }

  /// Stop monitoring
  void stopMonitoring() {
    _reportTimer?.cancel();
  }

  /// Record navigation metric
  void recordNavigation({
    required String fromRoute,
    required String toRoute,
    required Duration duration,
    required bool successful,
  }) {
    _metrics.add(NavigationMetric(
      fromRoute: fromRoute,
      toRoute: toRoute,
      duration: duration,
      successful: successful,
      timestamp: DateTime.now(),
    ));

    // Keep only recent metrics
    if (_metrics.length > 1000) {
      _metrics.removeAt(0);
    }
  }

  /// Generate performance report
  void _generateReport() {
    if (_metrics.isEmpty) return;

    final successfulNavigations = _metrics.where((m) => m.successful).length;
    final totalNavigations = _metrics.length;
    final successRate = successfulNavigations / totalNavigations;

    final averageDuration = _metrics
        .map((m) => m.duration.inMilliseconds)
        .reduce((a, b) => a + b) / _metrics.length;

    if (kDebugMode) {
      debugPrint('Navigation Performance Report:');
      debugPrint('Success Rate: ${(successRate * 100).toStringAsFixed(1)}%');
      debugPrint('Average Duration: ${averageDuration.toStringAsFixed(1)}ms');
      debugPrint('Total Navigations: $totalNavigations');
    }
  }

  /// Get performance statistics
  NavigationPerformanceStats getStats() {
    if (_metrics.isEmpty) {
      return const NavigationPerformanceStats(
        totalNavigations: 0,
        successfulNavigations: 0,
        averageDuration: Duration.zero,
        successRate: 0.0,
      );
    }

    final successful = _metrics.where((m) => m.successful).length;
    final avgDuration = _metrics
        .map((m) => m.duration.inMilliseconds)
        .reduce((a, b) => a + b) ~/ _metrics.length;

    return NavigationPerformanceStats(
      totalNavigations: _metrics.length,
      successfulNavigations: successful,
      averageDuration: Duration(milliseconds: avgDuration),
      successRate: successful / _metrics.length,
    );
  }

  /// Clear metrics
  void clearMetrics() {
    _metrics.clear();
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    clearMetrics();
  }
}

/// Navigation metric data class
class NavigationMetric {
  const NavigationMetric({
    required this.fromRoute,
    required this.toRoute,
    required this.duration,
    required this.successful,
    required this.timestamp,
  });

  final String fromRoute;
  final String toRoute;
  final Duration duration;
  final bool successful;
  final DateTime timestamp;
}

/// Navigation performance statistics
class NavigationPerformanceStats {
  const NavigationPerformanceStats({
    required this.totalNavigations,
    required this.successfulNavigations,
    required this.averageDuration,
    required this.successRate,
  });

  final int totalNavigations;
  final int successfulNavigations;
  final Duration averageDuration;
  final double successRate;

  /// Check if performance is good
  bool get isPerformanceGood => 
      successRate >= 0.95 && 
      averageDuration.inMilliseconds <= 500;
}

/// Optimized Navigator replacement
class OptimizedNavigator {
  static Future<T?> pushOptimized<T extends Object?>(
    BuildContext context, {
    required Widget page,
    required String routeName,
    RouteSettings? settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) {
    final route = NavigationOptimizer().createOptimizedRoute<T>(
      page: page,
      routeName: routeName,
      settings: settings,
      maintainState: maintainState,
      fullscreenDialog: fullscreenDialog,
    );

    final stopwatch = Stopwatch()..start();
    
    return Navigator.of(context).push(route).then((result) {
      stopwatch.stop();
      
      NavigationPerformanceMonitor().recordNavigation(
        fromRoute: ModalRoute.of(context)?.settings.name ?? 'unknown',
        toRoute: routeName,
        duration: stopwatch.elapsed,
        successful: true,
      );
      
      return result;
    }).catchError((error) {
      stopwatch.stop();
      
      NavigationPerformanceMonitor().recordNavigation(
        fromRoute: ModalRoute.of(context)?.settings.name ?? 'unknown',
        toRoute: routeName,
        duration: stopwatch.elapsed,
        successful: false,
      );
      
      throw error;
    });
  }

  static Future<T?> showOptimizedDialog<T extends Object?>(
    BuildContext context, {
    required WidgetBuilder builder,
    required String routeName,
    bool barrierDismissible = true,
    Color? barrierColor,
    String? barrierLabel,
  }) {
    final route = NavigationOptimizer().createOptimizedModalRoute<T>(
      builder: builder,
      routeName: routeName,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      barrierLabel: barrierLabel,
    );

    return Navigator.of(context).push(route);
  }
}