import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math' as math;

/// Advanced Animation Optimization and Management System
class AnimationOptimizer {
  static final AnimationOptimizer _instance = AnimationOptimizer._internal();
  factory AnimationOptimizer() => _instance;
  AnimationOptimizer._internal();

  // Animation management
  final Set<TickerProvider> _activeAnimations = {};
  final Map<String, AnimationController> _sharedControllers = {};
  
  // Performance settings
  bool _enableAnimations = true;
  bool _reduceMotion = false;
  double _globalAnimationScale = 1.0;
  
  // Animation pools
  final Map<Duration, List<AnimationController>> _controllerPools = {};
  final List<Tween<double>> _tweenPool = [];
  
  // Performance monitoring
  int _activeAnimationCount = 0;
  final List<Duration> _animationFrameTimes = [];

  /// Initialize animation optimizer
  void initialize() {
    _loadPerformanceSettings();
    _initializeTweenPool();
  }

  /// Load performance settings
  void _loadPerformanceSettings() {
    // In a real implementation, load from shared preferences
    _enableAnimations = true;
    _reduceMotion = false;
    _globalAnimationScale = 1.0;
  }

  /// Initialize tween pool
  void _initializeTweenPool() {
    // Pre-create common tweens
    for (int i = 0; i < 10; i++) {
      _tweenPool.add(Tween<double>(begin: 0.0, end: 1.0));
    }
  }

  /// Get or create shared animation controller
  AnimationController getSharedController(
    String key,
    TickerProvider vsync, {
    required Duration duration,
    Duration? reverseDuration,
    String? debugLabel,
    double value = 0.0,
    double lowerBound = 0.0,
    double upperBound = 1.0,
  }) {
    if (_sharedControllers.containsKey(key)) {
      return _sharedControllers[key]!;
    }

    final controller = createOptimizedController(
      vsync,
      duration: duration,
      reverseDuration: reverseDuration,
      debugLabel: debugLabel,
      value: value,
      lowerBound: lowerBound,
      upperBound: upperBound,
    );

    _sharedControllers[key] = controller;
    return controller;
  }

  /// Create optimized animation controller
  AnimationController createOptimizedController(
    TickerProvider vsync, {
    required Duration duration,
    Duration? reverseDuration,
    String? debugLabel,
    double value = 0.0,
    double lowerBound = 0.0,
    double upperBound = 1.0,
  }) {
    // Try to get from pool first
    final poolKey = duration;
    final pool = _controllerPools[poolKey];
    
    if (pool != null && pool.isNotEmpty) {
      final controller = pool.removeLast();
      controller.reset();
      controller.value = value;
      return controller;
    }

    // Create new controller with optimizations
    final scaledDuration = Duration(
      milliseconds: (duration.inMilliseconds * _globalAnimationScale).round(),
    );

    final controller = AnimationController(
      duration: scaledDuration,
      reverseDuration: reverseDuration != null
          ? Duration(milliseconds: (reverseDuration.inMilliseconds * _globalAnimationScale).round())
          : null,
      debugLabel: debugLabel,
      value: value,
      lowerBound: lowerBound,
      upperBound: upperBound,
      vsync: vsync,
    );

    _trackAnimation(controller, vsync);
    return controller;
  }

  /// Return controller to pool
  void returnController(AnimationController controller, Duration originalDuration) {
    if (!controller.isDisposed) {
      controller.stop();
      controller.reset();
      
      final pool = _controllerPools.putIfAbsent(originalDuration, () => <AnimationController>[]);
      if (pool.length < 5) { // Limit pool size
        pool.add(controller);
      } else {
        controller.dispose();
      }
    }
  }

  /// Get optimized tween
  Tween<T> getOptimizedTween<T>({
    required T begin,
    required T end,
  }) {
    if (T == double && _tweenPool.isNotEmpty) {
      final tween = _tweenPool.removeLast() as Tween<T>;
      return tween
        ..begin = begin
        ..end = end;
    }

    return Tween<T>(begin: begin, end: end);
  }

  /// Return tween to pool
  void returnTween<T>(Tween<T> tween) {
    if (T == double && _tweenPool.length < 20) {
      _tweenPool.add(tween as Tween<double>);
    }
  }

  /// Track animation for performance monitoring
  void _trackAnimation(AnimationController controller, TickerProvider vsync) {
    _activeAnimations.add(vsync);
    _activeAnimationCount++;

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        _activeAnimations.remove(vsync);
        _activeAnimationCount--;
      }
    });
  }

  /// Create staggered animation with optimization
  List<Animation<double>> createStaggeredAnimation(
    AnimationController controller, {
    required int count,
    required Duration interval,
    Curve curve = Curves.easeInOut,
    double overlap = 0.0,
  }) {
    if (!_enableAnimations) {
      // Return simple animations if animations are disabled
      return List.generate(count, (_) => AlwaysStoppedAnimation(1.0));
    }

    final animations = <Animation<double>>[];
    final intervalValue = interval.inMilliseconds / controller.duration!.inMilliseconds;
    
    for (int i = 0; i < count; i++) {
      final begin = (i * intervalValue * (1.0 - overlap)).clamp(0.0, 1.0);
      final end = math.min(begin + intervalValue + overlap, 1.0);
      
      final animation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(
        CurvedAnimation(
          parent: controller,
          curve: Interval(begin, end, curve: curve),
        ),
      );
      
      animations.add(animation);
    }
    
    return animations;
  }

  /// Set global animation settings
  void setAnimationSettings({
    bool? enableAnimations,
    bool? reduceMotion,
    double? animationScale,
  }) {
    _enableAnimations = enableAnimations ?? _enableAnimations;
    _reduceMotion = reduceMotion ?? _reduceMotion;
    _globalAnimationScale = animationScale ?? _globalAnimationScale;
  }

  /// Check if animations should be enabled
  bool get shouldAnimate => _enableAnimations && !_reduceMotion;

  /// Get current animation count
  int get activeAnimationCount => _activeAnimationCount;

  /// Get animation performance stats
  AnimationPerformanceStats getPerformanceStats() {
    return AnimationPerformanceStats(
      activeAnimations: _activeAnimationCount,
      pooledControllers: _controllerPools.values.fold(0, (sum, pool) => sum + pool.length),
      pooledTweens: _tweenPool.length,
      animationsEnabled: _enableAnimations,
      motionReduced: _reduceMotion,
      globalScale: _globalAnimationScale,
    );
  }

  /// Clear all pools and shared controllers
  void clearPools() {
    for (final pool in _controllerPools.values) {
      for (final controller in pool) {
        controller.dispose();
      }
    }
    _controllerPools.clear();
    
    for (final controller in _sharedControllers.values) {
      controller.dispose();
    }
    _sharedControllers.clear();
    
    _tweenPool.clear();
    _initializeTweenPool();
  }

  /// Dispose all resources
  void dispose() {
    clearPools();
    _activeAnimations.clear();
    _animationFrameTimes.clear();
  }
}

/// Animation performance statistics
class AnimationPerformanceStats {
  const AnimationPerformanceStats({
    required this.activeAnimations,
    required this.pooledControllers,
    required this.pooledTweens,
    required this.animationsEnabled,
    required this.motionReduced,
    required this.globalScale,
  });

  final int activeAnimations;
  final int pooledControllers;
  final int pooledTweens;
  final bool animationsEnabled;
  final bool motionReduced;
  final double globalScale;
}

/// Optimized Animation Widget
class OptimizedAnimatedWidget extends StatefulWidget {
  const OptimizedAnimatedWidget({
    super.key,
    required this.child,
    required this.animation,
    this.curve = Curves.linear,
    this.useRepaintBoundary = true,
    this.enableOptimizations = true,
  });

  final Widget child;
  final Animation<double> animation;
  final Curve curve;
  final bool useRepaintBoundary;
  final bool enableOptimizations;

  @override
  State<OptimizedAnimatedWidget> createState() => _OptimizedAnimatedWidgetState();
}

class _OptimizedAnimatedWidgetState extends State<OptimizedAnimatedWidget> {
  Widget? _cachedChild;
  double? _lastAnimationValue;

  @override
  Widget build(BuildContext context) {
    final animationValue = widget.animation.value;
    
    // Cache child widget if it hasn't changed
    if (widget.enableOptimizations && _cachedChild == null) {
      _cachedChild = widget.child;
    }

    // Skip rebuild if animation value hasn't changed significantly
    if (widget.enableOptimizations && 
        _lastAnimationValue != null &&
        (animationValue - _lastAnimationValue!).abs() < 0.001) {
      return _cachedChild ?? widget.child;
    }

    _lastAnimationValue = animationValue;
    final child = _cachedChild ?? widget.child;

    Widget result = AnimatedBuilder(
      animation: widget.animation,
      child: child,
      builder: (context, child) {
        final curvedValue = widget.curve.transform(animationValue);
        return Transform.scale(
          scale: curvedValue,
          child: child,
        );
      },
    );

    if (widget.useRepaintBoundary) {
      result = RepaintBoundary(child: result);
    }

    return result;
  }
}

/// High-performance fade transition
class OptimizedFadeTransition extends StatelessWidget {
  const OptimizedFadeTransition({
    super.key,
    required this.opacity,
    required this.child,
    this.alwaysIncludeSemantics = false,
  });

  final Animation<double> opacity;
  final Widget child;
  final bool alwaysIncludeSemantics;

  @override
  Widget build(BuildContext context) {
    if (!AnimationOptimizer().shouldAnimate) {
      return child;
    }

    return AnimatedBuilder(
      animation: opacity,
      child: child,
      builder: (context, child) {
        final opacityValue = opacity.value;
        
        // Skip rendering if completely transparent
        if (opacityValue <= 0.0) {
          return const SizedBox.shrink();
        }
        
        // Skip opacity widget if completely opaque
        if (opacityValue >= 1.0) {
          return child!;
        }
        
        return Opacity(
          opacity: opacityValue,
          alwaysIncludeSemantics: alwaysIncludeSemantics,
          child: child,
        );
      },
    );
  }
}

/// High-performance slide transition
class OptimizedSlideTransition extends StatelessWidget {
  const OptimizedSlideTransition({
    super.key,
    required this.position,
    required this.child,
    this.transformHitTests = true,
    this.textDirection,
  });

  final Animation<Offset> position;
  final Widget child;
  final bool transformHitTests;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    if (!AnimationOptimizer().shouldAnimate) {
      return child;
    }

    return AnimatedBuilder(
      animation: position,
      child: child,
      builder: (context, child) {
        final offset = position.value;
        
        // Skip transform if no offset
        if (offset == Offset.zero) {
          return child!;
        }
        
        return FractionalTranslation(
          translation: offset,
          transformHitTests: transformHitTests,
          child: child,
        );
      },
    );
  }
}

/// Optimized scale transition
class OptimizedScaleTransition extends StatelessWidget {
  const OptimizedScaleTransition({
    super.key,
    required this.scale,
    required this.child,
    this.alignment = Alignment.center,
    this.filterQuality,
  });

  final Animation<double> scale;
  final Widget child;
  final Alignment alignment;
  final FilterQuality? filterQuality;

  @override
  Widget build(BuildContext context) {
    if (!AnimationOptimizer().shouldAnimate) {
      return child;
    }

    return AnimatedBuilder(
      animation: scale,
      child: child,
      builder: (context, child) {
        final scaleValue = scale.value;
        
        // Skip transform if scale is 1.0
        if (scaleValue == 1.0) {
          return child!;
        }
        
        // Hide if scale is 0
        if (scaleValue <= 0.0) {
          return const SizedBox.shrink();
        }
        
        return Transform.scale(
          scale: scaleValue,
          alignment: alignment,
          filterQuality: filterQuality,
          child: child,
        );
      },
    );
  }
}

/// Performance-aware animation controller
class PerformanceAwareAnimationController extends AnimationController {
  PerformanceAwareAnimationController({
    required super.duration,
    super.reverseDuration,
    super.debugLabel,
    super.value,
    super.lowerBound,
    super.upperBound,
    super.animationBehavior,
    required super.vsync,
    this.performanceThreshold = 30.0, // fps
  });

  final double performanceThreshold;
  bool _performanceMode = false;
  
  @override
  TickerFuture forward({double? from}) {
    _checkPerformance();
    if (_performanceMode) {
      // Skip animation in performance mode
      value = upperBound;
      return TickerFuture.complete();
    }
    return super.forward(from: from);
  }

  @override
  TickerFuture reverse({double? from}) {
    _checkPerformance();
    if (_performanceMode) {
      // Skip animation in performance mode
      value = lowerBound;
      return TickerFuture.complete();
    }
    return super.reverse(from: from);
  }

  void _checkPerformance() {
    // Simple performance check - in real implementation,
    // you would check actual frame rate
    final currentAnimations = AnimationOptimizer().activeAnimationCount;
    _performanceMode = currentAnimations > 10;
  }
}

/// Animation presets for common use cases
class AnimationPresets {
  AnimationPresets._();

  // Duration presets
  static const Duration ultraFast = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration ultraSlow = Duration(milliseconds: 800);

  // Curve presets
  static const Curve easeInOutQuart = Curves.easeInOutQuart;
  static const Curve bounceIn = Curves.bounceIn;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve elasticIn = Curves.elasticIn;
  static const Curve elasticOut = Curves.elasticOut;

  // Custom curves
  static const Curve materialEasing = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve materialEasingAccelerate = Cubic(0.4, 0.0, 1.0, 1.0);
  static const Curve materialEasingDecelerate = Cubic(0.0, 0.0, 0.2, 1.0);

  /// Get duration based on animation type
  static Duration getDurationForType(AnimationType type) {
    switch (type) {
      case AnimationType.micro:
        return ultraFast;
      case AnimationType.short:
        return fast;
      case AnimationType.medium:
        return normal;
      case AnimationType.long:
        return slow;
      case AnimationType.extraLong:
        return ultraSlow;
    }
  }

  /// Get curve based on animation style
  static Curve getCurveForStyle(AnimationStyle style) {
    switch (style) {
      case AnimationStyle.linear:
        return Curves.linear;
      case AnimationStyle.easeIn:
        return Curves.easeIn;
      case AnimationStyle.easeOut:
        return Curves.easeOut;
      case AnimationStyle.easeInOut:
        return Curves.easeInOut;
      case AnimationStyle.bounce:
        return bounceOut;
      case AnimationStyle.elastic:
        return elasticOut;
      case AnimationStyle.material:
        return materialEasing;
    }
  }
}

/// Animation type enumeration
enum AnimationType {
  micro,
  short,
  medium,
  long,
  extraLong,
}

/// Animation style enumeration
enum AnimationStyle {
  linear,
  easeIn,
  easeOut,
  easeInOut,
  bounce,
  elastic,
  material,
}

/// Batch animation controller for multiple animations
class BatchAnimationController {
  BatchAnimationController(this._vsync);

  final TickerProvider _vsync;
  final List<AnimationController> _controllers = [];
  bool _disposed = false;

  /// Add controller to batch
  void addController(AnimationController controller) {
    if (!_disposed) {
      _controllers.add(controller);
    }
  }

  /// Remove controller from batch
  void removeController(AnimationController controller) {
    _controllers.remove(controller);
  }

  /// Forward all animations
  void forwardAll() {
    for (final controller in _controllers) {
      if (!controller.isDisposed) {
        controller.forward();
      }
    }
  }

  /// Reverse all animations
  void reverseAll() {
    for (final controller in _controllers) {
      if (!controller.isDisposed) {
        controller.reverse();
      }
    }
  }

  /// Reset all animations
  void resetAll() {
    for (final controller in _controllers) {
      if (!controller.isDisposed) {
        controller.reset();
      }
    }
  }

  /// Stop all animations
  void stopAll() {
    for (final controller in _controllers) {
      if (!controller.isDisposed) {
        controller.stop();
      }
    }
  }

  /// Dispose all controllers
  void dispose() {
    if (_disposed) return;
    
    for (final controller in _controllers) {
      if (!controller.isDisposed) {
        controller.dispose();
      }
    }
    _controllers.clear();
    _disposed = true;
  }

  /// Get active controller count
  int get activeCount => _controllers.where((c) => !c.isDisposed).length;
}

/// Animation sequence builder
class AnimationSequence {
  AnimationSequence();

  final List<_SequenceStep> _steps = [];

  /// Add animation step
  AnimationSequence then(
    AnimationController controller, {
    Duration? delay,
    VoidCallback? onComplete,
  }) {
    _steps.add(_SequenceStep(
      controller: controller,
      delay: delay ?? Duration.zero,
      onComplete: onComplete,
    ));
    return this;
  }

  /// Execute sequence
  Future<void> execute() async {
    for (final step in _steps) {
      if (step.delay > Duration.zero) {
        await Future.delayed(step.delay);
      }
      
      await step.controller.forward();
      step.onComplete?.call();
    }
  }

  /// Execute sequence in reverse
  Future<void> executeReverse() async {
    for (final step in _steps.reversed) {
      await step.controller.reverse();
      step.onComplete?.call();
      
      if (step.delay > Duration.zero) {
        await Future.delayed(step.delay);
      }
    }
  }
}

class _SequenceStep {
  const _SequenceStep({
    required this.controller,
    required this.delay,
    this.onComplete,
  });

  final AnimationController controller;
  final Duration delay;
  final VoidCallback? onComplete;
}