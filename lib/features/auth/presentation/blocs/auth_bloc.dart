import 'package:asoud/core/helper/secure_storage.dart';
import 'package:bloc/bloc.dart';

import 'package:asoud/core/ui/ui_status.dart';
import 'package:asoud/core/network/app_result.dart';
import 'package:asoud/features/auth/data/repository/auth_repository_imp.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepositoryImp authRepository;
  AuthBloc({required this.authRepository}) : super(AuthState.initial()) {
    on<SendOtp>((event, emit) async {
      await _sendOtp(event, emit);
    });
    on<ToggleTermsCheckboxEvent>((event, emit) {
      emit(state.copyWith(termStatus: event.isClicked));
    });
    on<Logout>((event, emit) async {
      await _logout(event, emit);
    });
    on<VerifyOtp>((event, emit) async {
      await _verifyOtp(event, emit);
    });
  }

  //send otp
  _sendOtp(SendOtp event, Emitter<AuthState> emit) async {
    emit(state.copyWith(phoneNumber: event.phone, status: const UiLoading()));
    
    final result = await authRepository.userAuth(event.phone);
    result.fold(
      success: (data) {
        emit(state.copyWith(status: const UiSuccess()));
      },
      failure: (error) {
        emit(state.copyWith(
          status: UiError(error.toString()),
          error: error.toString(),
        ));
      },
    );
  }

  //verify otp
  _verifyOtp(VerifyOtp event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: const UiLoading()));
    
    final result = await authRepository.verifyUser(event.phone, event.otp);
    result.fold(
      success: (token) {
        emit(state.copyWith(status: const UiSuccess()));
      },
      failure: (error) {
        emit(state.copyWith(
          status: UiError(error.toString()),
          error: error.toString(),
        ));
      },
    );
  }

  //logout user
  _logout(Logout event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: const UiLoading()));
    
    final result = await authRepository.logoutUser();
    result.fold(
      success: (data) {
        emit(state.copyWith(status: const UiSuccess()));
      },
      failure: (error) {
        emit(state.copyWith(
          status: UiError(error.toString()),
          error: error.toString(),
        ));
      },
    );
  }
}
