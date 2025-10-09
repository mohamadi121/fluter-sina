import 'dart:async';
import 'package:flutter/material.dart';

abstract class BaseStatefulWidget extends StatefulWidget {
  const BaseStatefulWidget({super.key});
}

abstract class BaseState<T extends BaseStatefulWidget> extends State<T>
    with AutomaticKeepAliveClientMixin {
  final List<StreamSubscription> _subscriptions = <StreamSubscription>[];
  final List<Timer> _timers = <Timer>[];

  bool _isDisposed = false;

  @override
  bool get wantKeepAlive => false;

  bool get isDisposed => _isDisposed;

  void addSubscription(StreamSubscription subscription) {
    if (!_isDisposed) {
      _subscriptions.add(subscription);
    }
  }

  void addTimer(Timer timer) {
    if (!_isDisposed) {
      _timers.add(timer);
    }
  }

  @protected
  void logInfo(String message) {
    debugPrint('[$runtimeType] $message');
  }

  @protected
  void logError(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('[$runtimeType] ERROR: $message');
    if (error != null) debugPrint('Error: $error');
    if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
  }

  @override
  void dispose() {
    _isDisposed = true;

    for (final subscription in _subscriptions) {
      subscription.cancel();
    }

    for (final timer in _timers) {
      timer.cancel();
    }

    _subscriptions.clear();
    _timers.clear();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return buildWidget(context);
  }

  @protected
  Widget buildWidget(BuildContext context);
}