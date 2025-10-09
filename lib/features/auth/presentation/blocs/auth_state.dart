part of 'auth_bloc.dart';

class AuthState extends BaseBlocState<String> {
  final String phoneNumber;
  final bool termStatus;

  const AuthState({
    this.phoneNumber = '',
    this.termStatus = false,
    super.status = StateStatus.initial,
    super.error,
    super.data,
  });

  factory AuthState.initial() {
    return const AuthState(
      phoneNumber: '',
      termStatus: false,
      status: StateStatus.initial,
    );
  }

  @override
  AuthState copyWith({
    String? phoneNumber,
    bool? termStatus,
    StateStatus? status,
    String? error,
    String? data,
  }) {
    return AuthState(
      phoneNumber: phoneNumber ?? this.phoneNumber,
      termStatus: termStatus ?? this.termStatus,
      status: status ?? this.status,
      error: error ?? this.error,
      data: data ?? this.data,
    );
  }

  @override
  List<Object?> get props => [
    phoneNumber,
    termStatus,
    status,
    error,
    data,
  ];
}
