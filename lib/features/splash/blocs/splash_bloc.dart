import 'package:asood/core/auth/auth_session.dart';
import 'package:bloc/bloc.dart';

part 'splash_event.dart';
part 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final AuthSession authSession;

  SplashBloc(this.authSession) : super(SplashState.initial()) {
    on<SplashInitialEvent>((event, emit) async {
      emit(const SplashState(status: SplashStatus.loading));

      if (!authSession.isHydrated) {
        await authSession.hydrate();
      }

      emit(
        SplashState(
          status:
              authSession.isAuthenticated
                  ? SplashStatus.exist
                  : SplashStatus.notExist,
        ),
      );
    });
  }
}
