import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/store_setting_screens/takhfif_setting_screen/data/discount_api_service.dart';

part 'discount_state.dart';

class DiscountCubit extends Cubit<DiscountState> {
  final DiscountApiService api;

  DiscountCubit({required this.api}) : super(const DiscountState());

  Future<void> load() async {
    emit(state.copyWith(status: DiscountStatus.loading));

    final res = await api.list();
    if (res is! Success) {
      emit(
        state.copyWith(
          status: DiscountStatus.failure,
          error: res is Failure ? res.message : 'خطای نامشخص',
        ),
      );
      return;
    }

    final data = res.response;
    emit(
      state.copyWith(
        status: DiscountStatus.loaded,
        discounts:
            data is List
                ? data
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
                : const [],
      ),
    );
  }

  /// Creates a discount for a market or product and reloads the list.
  Future<void> create({
    required String contentType,
    required String objectId,
    required int percentage,
    required DateTime expiry,
    int? limitation,
  }) async {
    emit(state.copyWith(status: DiscountStatus.saving));

    final res = await api.create({
      'content_type': contentType,
      'object_id': objectId,
      'percentage': percentage,
      'expiry': expiry.toIso8601String(),
      if (limitation != null) 'limitation': limitation,
    });

    if (res is Success) {
      emit(state.copyWith(status: DiscountStatus.saved));
      await load();
      return;
    }
    emit(
      state.copyWith(
        status: DiscountStatus.failure,
        error: res is Failure ? res.message : 'ثبت تخفیف ناموفق بود',
      ),
    );
  }

  Future<void> delete(String discountId) async {
    final res = await api.delete(discountId);
    if (res is Success) {
      emit(
        state.copyWith(
          discounts:
              state.discounts
                  .where((d) => d['id'].toString() != discountId)
                  .toList(),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        error: res is Failure ? res.message : 'حذف تخفیف ناموفق بود',
      ),
    );
  }
}
