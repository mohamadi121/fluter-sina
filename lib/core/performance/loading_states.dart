import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../responsive/responsive_design.dart';

/// Advanced Loading States Management System
class LoadingStateManager {
  static final LoadingStateManager _instance = LoadingStateManager._internal();
  factory LoadingStateManager() => _instance;
  LoadingStateManager._internal();

  final Map<String, LoadingState> _loadingStates = {};
  final Map<String, List<VoidCallback>> _listeners = {};

  /// Set loading state for a specific operation
  void setLoading(String operationId, {String? message, double? progress}) {
    final state = LoadingState(
      isLoading: true,
      message: message,
      progress: progress,
      timestamp: DateTime.now(),
    );
    
    _loadingStates[operationId] = state;
    _notifyListeners(operationId);
  }

  /// Set success state for a specific operation
  void setSuccess(String operationId, {String? message}) {
    final state = LoadingState(
      isLoading: false,
      isSuccess: true,
      message: message,
      timestamp: DateTime.now(),
    );
    
    _loadingStates[operationId] = state;
    _notifyListeners(operationId);
  }

  /// Set error state for a specific operation
  void setError(String operationId, {String? message, dynamic error}) {
    final state = LoadingState(
      isLoading: false,
      isError: true,
      message: message,
      error: error,
      timestamp: DateTime.now(),
    );
    
    _loadingStates[operationId] = state;
    _notifyListeners(operationId);
  }

  /// Clear loading state
  void clearState(String operationId) {
    _loadingStates.remove(operationId);
    _notifyListeners(operationId);
  }

  /// Get current loading state
  LoadingState? getState(String operationId) {
    return _loadingStates[operationId];
  }

  /// Check if operation is loading
  bool isLoading(String operationId) {
    return _loadingStates[operationId]?.isLoading ?? false;
  }

  /// Add listener for state changes
  void addListener(String operationId, VoidCallback listener) {
    _listeners.putIfAbsent(operationId, () => []).add(listener);
  }

  /// Remove listener
  void removeListener(String operationId, VoidCallback listener) {
    _listeners[operationId]?.remove(listener);
  }

  /// Notify listeners of state change
  void _notifyListeners(String operationId) {
    final listeners = _listeners[operationId];
    if (listeners != null) {
      for (final listener in listeners) {
        listener();
      }
    }
  }

  /// Clear all states
  void clearAll() {
    _loadingStates.clear();
    for (final listeners in _listeners.values) {
      for (final listener in listeners) {
        listener();
      }
    }
  }
}

/// Loading state data class
class LoadingState {
  const LoadingState({
    this.isLoading = false,
    this.isSuccess = false,
    this.isError = false,
    this.message,
    this.progress,
    this.error,
    required this.timestamp,
  });

  final bool isLoading;
  final bool isSuccess;
  final bool isError;
  final String? message;
  final double? progress;
  final dynamic error;
  final DateTime timestamp;

  bool get isIdle => !isLoading && !isSuccess && !isError;

  LoadingState copyWith({
    bool? isLoading,
    bool? isSuccess,
    bool? isError,
    String? message,
    double? progress,
    dynamic error,
    DateTime? timestamp,
  }) {
    return LoadingState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      isError: isError ?? this.isError,
      message: message ?? this.message,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}

/// Adaptive Loading Widget
class AsoudLoading extends StatefulWidget {
  const AsoudLoading({
    super.key,
    this.size = LoadingSize.medium,
    this.type = LoadingType.circular,
    this.color,
    this.message,
    this.showMessage = true,
    this.showProgress = true,
    this.progress,
    this.backgroundColor,
    this.overlay = false,
  });

  final LoadingSize size;
  final LoadingType type;
  final Color? color;
  final String? message;
  final bool showMessage;
  final bool showProgress;
  final double? progress;
  final Color? backgroundColor;
  final bool overlay;

  @override
  State<AsoudLoading> createState() => _AsoudLoadingState();
}

class _AsoudLoadingState extends State<AsoudLoading>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.repeat();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveDesign(context);
    final theme = Theme.of(context);
    
    final size = _getLoadingSize(responsive);
    final color = widget.color ?? theme.colorScheme.primary;

    Widget loadingWidget = _buildLoadingIndicator(size, color);

    if (widget.showMessage && widget.message != null) {
      loadingWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loadingWidget,
          SizedBox(height: responsive.scale(16)),
          Text(
            widget.message!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: responsive.scale(14),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    if (widget.showProgress && widget.progress != null) {
      loadingWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          loadingWidget,
          SizedBox(height: responsive.scale(12)),
          SizedBox(
            width: size,
            child: LinearProgressIndicator(
              value: widget.progress,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          SizedBox(height: responsive.scale(8)),
          Text(
            '${(widget.progress! * 100).toInt()}%',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: responsive.scale(12),
            ),
          ),
        ],
      );
    }

    if (widget.overlay) {
      return Material(
        color: widget.backgroundColor ?? Colors.black54,
        child: Center(
          child: Container(
            padding: EdgeInsets.all(responsive.scale(24)),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(responsive.scale(12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: responsive.scale(8),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: loadingWidget,
          ),
        ),
      );
    }

    return loadingWidget;
  }

  Widget _buildLoadingIndicator(double size, Color color) {
    switch (widget.type) {
      case LoadingType.circular:
        return SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: size * 0.08,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      
      case LoadingType.linear:
        return SizedBox(
          width: size * 2,
          child: LinearProgressIndicator(
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        );
      
      case LoadingType.dots:
        return _buildDotsIndicator(size, color);
      
      case LoadingType.pulse:
        return _buildPulseIndicator(size, color);
      
      case LoadingType.wave:
        return _buildWaveIndicator(size, color);
    }
  }

  Widget _buildDotsIndicator(double size, Color color) {
    return SizedBox(
      width: size,
      height: size * 0.3,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final delay = index * 0.2;
              final value = _animation.value;
              final opacity = value > delay
                  ? (value - delay) / (1 - delay)
                  : 0.0;
              
              return Opacity(
                opacity: opacity.clamp(0.3, 1.0),
                child: Container(
                  width: size * 0.15,
                  height: size * 0.15,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildPulseIndicator(double size, Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final scale = 0.8 + (_animation.value * 0.4);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color.withOpacity(0.8 - (_animation.value * 0.5)),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaveIndicator(double size, Color color) {
    return SizedBox(
      width: size,
      height: size * 0.5,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = (_animation.value + (index * 0.1)) % 1.0;
              final height = (1.0 - value) * size * 0.5;
              
              return Container(
                width: size * 0.08,
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(size * 0.04),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  double _getLoadingSize(ResponsiveDesign responsive) {
    switch (widget.size) {
      case LoadingSize.small:
        return responsive.scale(24);
      case LoadingSize.medium:
        return responsive.scale(40);
      case LoadingSize.large:
        return responsive.scale(64);
      case LoadingSize.extraLarge:
        return responsive.scale(80);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Loading size enumeration
enum LoadingSize {
  small,
  medium,
  large,
  extraLarge,
}

/// Loading type enumeration
enum LoadingType {
  circular,
  linear,
  dots,
  pulse,
  wave,
}

/// Error Display Widget
class AsoudError extends StatelessWidget {
  const AsoudError({
    super.key,
    required this.error,
    this.title,
    this.message,
    this.onRetry,
    this.retryText,
    this.showDetails = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
  });

  final dynamic error;
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryText;
  final bool showDetails;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveDesign(context);
    final theme = Theme.of(context);
    
    final errorInfo = _parseError(error);
    
    return Container(
      padding: EdgeInsets.all(responsive.scale(16)),
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(responsive.scale(8)),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Error icon
          Icon(
            icon ?? errorInfo.icon,
            size: responsive.scale(48),
            color: textColor ?? theme.colorScheme.error,
          ),
          
          SizedBox(height: responsive.scale(16)),
          
          // Error title
          Text(
            title ?? errorInfo.title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: textColor ?? theme.colorScheme.onErrorContainer,
              fontSize: responsive.scale(16),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: responsive.scale(8)),
          
          // Error message
          Text(
            message ?? errorInfo.message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor ?? theme.colorScheme.onErrorContainer,
              fontSize: responsive.scale(14),
            ),
            textAlign: TextAlign.center,
          ),
          
          // Error details
          if (showDetails && errorInfo.details != null) ...[
            SizedBox(height: responsive.scale(12)),
            Container(
              padding: EdgeInsets.all(responsive.scale(12)),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(responsive.scale(6)),
              ),
              child: SelectableText(
                errorInfo.details!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontSize: responsive.scale(12),
                ),
              ),
            ),
          ],
          
          // Retry button
          if (onRetry != null) ...[
            SizedBox(height: responsive.scale(16)),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryText ?? 'تلاش مجدد'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.scale(16),
                  vertical: responsive.scale(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  ErrorInfo _parseError(dynamic error) {
    if (error is NetworkException) {
      return ErrorInfo(
        icon: Icons.wifi_off,
        title: 'خطای اتصال',
        message: 'لطفاً اتصال اینترنت خود را بررسی کنید',
        details: error.toString(),
      );
    } else if (error is TimeoutException) {
      return ErrorInfo(
        icon: Icons.access_time,
        title: 'خطای زمان',
        message: 'درخواست زمان زیادی طول کشید',
        details: error.toString(),
      );
    } else if (error is AuthenticationException) {
      return ErrorInfo(
        icon: Icons.lock_outline,
        title: 'خطای احراز هویت',
        message: 'لطفاً مجدداً وارد شوید',
        details: error.toString(),
      );
    } else if (error is ValidationException) {
      return ErrorInfo(
        icon: Icons.warning_amber,
        title: 'خطای اعتبارسنجی',
        message: error.message ?? 'داده‌های ورودی نامعتبر است',
        details: error.toString(),
      );
    } else if (error is ServerException) {
      return ErrorInfo(
        icon: Icons.cloud_off,
        title: 'خطای سرور',
        message: 'مشکلی در سرور رخ داده است',
        details: error.toString(),
      );
    } else {
      return ErrorInfo(
        icon: Icons.error_outline,
        title: 'خطای ناشناخته',
        message: 'مشکلی رخ داده است',
        details: error.toString(),
      );
    }
  }
}

/// Error information class
class ErrorInfo {
  const ErrorInfo({
    required this.icon,
    required this.title,
    required this.message,
    this.details,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? details;
}

/// Custom exception classes
class NetworkException implements Exception {
  const NetworkException(this.message);
  final String message;
  
  @override
  String toString() => 'NetworkException: $message';
}

class TimeoutException implements Exception {
  const TimeoutException(this.message);
  final String message;
  
  @override
  String toString() => 'TimeoutException: $message';
}

class AuthenticationException implements Exception {
  const AuthenticationException(this.message);
  final String message;
  
  @override
  String toString() => 'AuthenticationException: $message';
}

class ValidationException implements Exception {
  const ValidationException(this.message);
  final String message;
  
  @override
  String toString() => 'ValidationException: $message';
}

class ServerException implements Exception {
  const ServerException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;
  
  @override
  String toString() => 'ServerException: $message${statusCode != null ? ' (${statusCode})' : ''}';
}

/// Loading State Builder Widget
class LoadingStateBuilder extends StatefulWidget {
  const LoadingStateBuilder({
    super.key,
    required this.operationId,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.successBuilder,
  });

  final String operationId;
  final Widget Function(BuildContext context, LoadingState? state) builder;
  final Widget Function(BuildContext context, LoadingState state)? loadingBuilder;
  final Widget Function(BuildContext context, LoadingState state)? errorBuilder;
  final Widget Function(BuildContext context, LoadingState state)? successBuilder;

  @override
  State<LoadingStateBuilder> createState() => _LoadingStateBuilderState();
}

class _LoadingStateBuilderState extends State<LoadingStateBuilder> {
  LoadingState? _currentState;

  @override
  void initState() {
    super.initState();
    _currentState = LoadingStateManager().getState(widget.operationId);
    LoadingStateManager().addListener(widget.operationId, _onStateChanged);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentState == null) {
      return widget.builder(context, null);
    }

    if (_currentState!.isLoading && widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context, _currentState!);
    }

    if (_currentState!.isError && widget.errorBuilder != null) {
      return widget.errorBuilder!(context, _currentState!);
    }

    if (_currentState!.isSuccess && widget.successBuilder != null) {
      return widget.successBuilder!(context, _currentState!);
    }

    return widget.builder(context, _currentState);
  }

  void _onStateChanged() {
    if (mounted) {
      setState(() {
        _currentState = LoadingStateManager().getState(widget.operationId);
      });
    }
  }

  @override
  void dispose() {
    LoadingStateManager().removeListener(widget.operationId, _onStateChanged);
    super.dispose();
  }
}

/// Future Builder with enhanced error handling
class AsoudFutureBuilder<T> extends StatelessWidget {
  const AsoudFutureBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.loadingWidget,
    this.errorWidget,
    this.loadingMessage,
    this.showProgress = false,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final String? loadingMessage;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return loadingWidget ??
              AsoudLoading(
                message: loadingMessage,
                showProgress: showProgress,
                overlay: true,
              );
        }

        if (snapshot.hasError) {
          return errorWidget ??
              AsoudError(
                error: snapshot.error,
                onRetry: () {
                  // Trigger rebuild
                  (context as Element).markNeedsBuild();
                },
              );
        }

        if (snapshot.hasData) {
          return builder(context, snapshot.data!);
        }

        return const SizedBox.shrink();
      },
    );
  }
}