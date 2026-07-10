import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/affiliate/data/affiliate_api_service.dart';

part 'affiliate_state.dart';

/// Lists products available to affiliate-market. Creating an affiliate
/// product reloads the available list.
class AffiliateCubit extends Cubit<AffiliateState> {
  final AffiliateApiService api;

  AffiliateCubit({required this.api}) : super(const AffiliateState());

  Future<void> loadAvailable() async {
    emit(state.copyWith(status: AffiliateStatus.loading));

    final res = await api.availableProducts();
    if (res is! Success) {
      emit(
        state.copyWith(
          status: AffiliateStatus.failure,
          error: res is Failure ? res.message : 'خطای نامشخص',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: AffiliateStatus.loaded,
        products: _asList(res.response),
      ),
    );
  }

  Future<bool> create(Map<String, dynamic> body) async {
    emit(state.copyWith(status: AffiliateStatus.creating));

    final res = await api.create(body);
    if (res is Success) {
      await loadAvailable();
      return true;
    }
    emit(
      state.copyWith(
        status: AffiliateStatus.failure,
        error: res is Failure ? res.message : 'ثبت ناموفق بود',
      ),
    );
    return false;
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    final list = data is Map ? data['results'] : data;
    if (list is! List) {
      return const [];
    }
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
