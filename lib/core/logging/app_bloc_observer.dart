import 'package:flutter_bloc/flutter_bloc.dart';

import 'app_logger.dart';

/// Global BLoC observer: every state-management error is logged with its
/// stack trace, transitions are traced at debug level.
class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    AppLogger.debug(
      'bloc',
      '${bloc.runtimeType}: ${transition.event.runtimeType} -> '
          '${transition.nextState.runtimeType}',
    );
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    AppLogger.error('bloc', '${bloc.runtimeType} failed', error, stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}
