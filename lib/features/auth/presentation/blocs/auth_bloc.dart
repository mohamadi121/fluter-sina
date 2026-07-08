import 'package:bloc/bloc.dart';

import 'package:asood/core/auth/auth_session.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/auth/domain/repository/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;
  final AuthSession authSession;

  AuthBloc({required this.authRepository, required this.authSession})
    : super(AuthState.initial()) {
    on<SendOtp>(_sendOtp);
    on<VerifyOtp>(_verifyOtp);
    on<Logout>(_logout);
    on<ToggleTermsCheckboxEvent>((event, emit) {
      emit(state.copyWith(termStatus: event.isClicked));
    });
  }

  Future<void> _sendOtp(SendOtp event, Emitter<AuthState> emit) async {
    emit(
      state.copyWith(phoneNumber: event.phone, status: AuthStatus.sendingOtp),
    );

    final res = await authRepository.sendCode(event.phone);
    if (res is Success) {
      emit(state.copyWith(status: AuthStatus.otpSent));
      return;
    }
    emit(
      state.copyWith(
        status: AuthStatus.error,
        error: res is Failure ? res.message : 'خطای نامشخص',
      ),
    );
  }

  Future<void> _verifyOtp(VerifyOtp event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.verifying));

    final res = await authRepository.verifyCode(event.phone, event.otp);
    if (res is! Success) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          error: res is Failure ? res.message : 'خطای نامشخص',
        ),
      );
      return;
    }

    final token = (res.response as Map?)?['token']?.toString();
    if (token == null || token.isEmpty) {
      emit(
        state.copyWith(
          status: AuthStatus.error,
          error: 'پاسخ ورود فاقد توکن است',
        ),
      );
      return;
    }

    await authSession.setToken(token);
    emit(state.copyWith(status: AuthStatus.authenticated));
  }

  Future<void> _logout(Logout event, Emitter<AuthState> emit) async {
    await authSession.clear();
    emit(AuthState.initial());
  }
}
