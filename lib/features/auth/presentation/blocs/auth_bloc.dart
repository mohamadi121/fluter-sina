import 'package:asood/core/helper/secure_storage.dart';
import 'package:asood/core/architecture/base_bloc.dart';
import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/architecture/bloc_state.dart';
import 'package:asood/features/auth/domain/usecases/auth_usecases.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends BaseBloc<AuthEvent, AuthState> {
  final SendOtpUseCase sendOtpUseCase;
  final VerifyOtpUseCase verifyOtpUseCase;
  final LogoutUseCase logoutUseCase;
  
  AuthBloc({
    required this.sendOtpUseCase,
    required this.verifyOtpUseCase,
    required this.logoutUseCase,
  }) : super(AuthState.initial()) {
    on<SendOtp>(_onSendOtp);
    on<ToggleTermsCheckboxEvent>(_onToggleTerms);
    on<Logout>(_onLogout);
    on<VerifyOtp>(_onVerifyOtp);
  }

  Future<void> _onSendOtp(SendOtp event, Emitter<AuthState> emit) async {
    logInfo('Sending OTP to ${event.phone}');
    emit(state.copyWith(phoneNumber: event.phone, status: StateStatus.loading));
    
    final result = await sendOtpUseCase(SendOtpParams(phoneNumber: event.phone));
    
    result.fold(
      (failure) {
        logError('Failed to send OTP', failure);
        emit(state.copyWith(
          status: StateStatus.error,
          error: failure.message,
        ));
      },
      (success) {
        logInfo('OTP sent successfully');
        emit(state.copyWith(status: StateStatus.success));
      },
    );
  }

  void _onToggleTerms(ToggleTermsCheckboxEvent event, Emitter<AuthState> emit) {
    emit(state.copyWith(termStatus: event.isClicked));
  }

  Future<void> _onLogout(Logout event, Emitter<AuthState> emit) async {
    logInfo('Logging out user');
    
    final result = await logoutUseCase(NoParams());
    
    result.fold(
      (failure) {
        logError('Error during logout', failure);
        // Still reset state even if logout fails
        emit(AuthState.initial());
      },
      (success) {
        logInfo('User logged out successfully');
        emit(AuthState.initial());
      },
    );
  }

  Future<void> _onVerifyOtp(VerifyOtp event, Emitter<AuthState> emit) async {
    logInfo('Verifying OTP for ${event.phone}');
    emit(state.copyWith(status: StateStatus.loading));
    
    final result = await verifyOtpUseCase(
      VerifyOtpParams(phoneNumber: event.phone, otp: event.otp)
    );
    
    result.fold(
      (failure) {
        logError('Failed to verify OTP', failure);
        emit(state.copyWith(
          status: StateStatus.error,
          error: failure.message,
        ));
      },
      (authData) {
        logInfo('OTP verified successfully');
        emit(state.copyWith(status: StateStatus.success));
      },
    );
  }
}
