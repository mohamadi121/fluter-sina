import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/profile/data/profile_api_service.dart';

part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileApiService api;

  ProfileCubit({required this.api}) : super(const ProfileState());

  Future<void> load() async {
    emit(state.copyWith(status: ProfileStatus.loading, error: null));
    final result = await api.getProfile();
    if (result is! Success || result.response is! Map) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          error: result is Failure ? result.message : 'پاسخ نامعتبر سرور',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: ProfileStatus.loaded,
        data: Map<String, dynamic>.from(result.response as Map),
        error: null,
      ),
    );
  }

  Future<bool> save(Map<String, dynamic> body) async {
    emit(state.copyWith(status: ProfileStatus.saving, error: null));
    final result = await api.updateProfile(body);
    if (result is! Success || result.response is! Map) {
      emit(
        state.copyWith(
          status: ProfileStatus.failure,
          error:
              result is Failure ? result.message : 'ذخیره پروفایل ناموفق بود',
        ),
      );
      return false;
    }
    emit(
      state.copyWith(
        status: ProfileStatus.loaded,
        data: Map<String, dynamic>.from(result.response as Map),
        error: null,
      ),
    );
    return true;
  }
}
