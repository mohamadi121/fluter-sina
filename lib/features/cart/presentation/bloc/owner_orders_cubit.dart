import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/cart/data/data_source/owner_order_api_service.dart';

part 'owner_orders_state.dart';

/// Seller's incoming orders: list + accept/reject (verify).
class OwnerOrdersCubit extends Cubit<OwnerOrdersState> {
  final OwnerOrderApiService api;

  OwnerOrdersCubit({required this.api}) : super(const OwnerOrdersState());

  Future<void> load() async {
    emit(state.copyWith(status: OwnerOrdersStatus.loading));

    final res = await api.list();
    if (res is! Success) {
      emit(
        state.copyWith(
          status: OwnerOrdersStatus.failure,
          error: res is Failure ? res.message : 'خطای نامشخص',
        ),
      );
      return;
    }

    final data = res.response;
    final list = data is Map ? data['results'] : data;
    emit(
      state.copyWith(
        status: OwnerOrdersStatus.loaded,
        orders:
            list is List
                ? list
                    .whereType<Map>()
                    .map((e) => Map<String, dynamic>.from(e))
                    .toList()
                : const [],
      ),
    );
  }

  Future<bool> verify({
    required String id,
    required bool verified,
    String description = '',
  }) async {
    final res = await api.verify(
      id: id,
      verified: verified,
      description: description,
    );
    if (res is Success) {
      await load();
      return true;
    }
    emit(
      state.copyWith(
        error: res is Failure ? res.message : 'ثبت وضعیت ناموفق بود',
      ),
    );
    return false;
  }
}
