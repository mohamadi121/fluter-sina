import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

abstract class BaseBloc<Event, State> extends Bloc<Event, State> {
  BaseBloc(super.initialState);

  final List<StreamSubscription> _subscriptions = <StreamSubscription>[];
  final List<Timer> _timers = <Timer>[];

  bool _isDisposed = false;

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
    if (kDebugMode) {
      debugPrint('[$runtimeType] $message');
    }
  }

  @protected
  void logError(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[$runtimeType] ERROR: $message');
      if (error != null) debugPrint('Error: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
  }

  @override
  Future<void> close() async {
    _isDisposed = true;
    
    await Future.wait([
      ..._subscriptions.map((subscription) => subscription.cancel()),
    ]);
    
    for (final timer in _timers) {
      timer.cancel();
    }
    
    _subscriptions.clear();
    _timers.clear();
    
    return super.close();
  }
}