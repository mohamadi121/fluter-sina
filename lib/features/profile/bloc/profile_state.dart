part of 'profile_cubit.dart';

enum ProfileStatus { initial, loading, loaded, saving, failure }

class ProfileState extends Equatable {
  final ProfileStatus status;
  final Map<String, dynamic> data;
  final String? error;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.data = const {},
    this.error,
  });

  ProfileState copyWith({
    ProfileStatus? status,
    Map<String, dynamic>? data,
    String? error,
  }) {
    return ProfileState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, data, error];
}
