import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/referral/data/referral_api_service.dart';

part 'referral_state.dart';

class ReferralCubit extends Cubit<ReferralState> {
  final ReferralApiService api;

  ReferralCubit({required this.api}) : super(const ReferralState());

  Future<void> load() async {
    emit(state.copyWith(status: ReferralStatus.loading));
    final result = await api.summary();
    if (result is! Success || result.response is! Map) {
      emit(
        state.copyWith(
          status: ReferralStatus.failure,
          error: result is Failure ? result.message : 'پاسخ نامعتبر سرور',
        ),
      );
      return;
    }
    final data = Map<String, dynamic>.from(result.response as Map);
    emit(
      state.copyWith(
        status: ReferralStatus.loaded,
        referralCount: (data['referral_count'] as num?)?.toInt() ?? 0,
        referredUserIds:
            (data['referrees'] as List? ?? const [])
                .whereType<Map>()
                .map((item) => item['id']?.toString())
                .whereType<String>()
                .toList(),
        error: null,
      ),
    );
  }

  Future<bool> applyCode(String code) async {
    final normalizedCode = code.trim();
    if (normalizedCode.isEmpty) {
      emit(
        state.copyWith(
          status: ReferralStatus.failure,
          error: 'کد معرف را وارد کنید',
        ),
      );
      return false;
    }
    emit(state.copyWith(status: ReferralStatus.submitting, error: null));
    final result = await api.applyCode(normalizedCode);
    if (result is! Success) {
      emit(
        state.copyWith(
          status: ReferralStatus.failure,
          error: result is Failure ? result.message : 'ثبت کد معرف ناموفق بود',
        ),
      );
      return false;
    }
    await load();
    return true;
  }
}
