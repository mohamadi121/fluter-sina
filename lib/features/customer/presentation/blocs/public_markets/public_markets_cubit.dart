import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/core/models/market_model.dart';
import 'package:asood/features/customer/data/public_market_api_service.dart';

part 'public_markets_state.dart';

class PublicMarketsCubit extends Cubit<PublicMarketsState> {
  final PublicMarketApiService api;

  PublicMarketsCubit({required this.api}) : super(const PublicMarketsState());

  Future<void> load({String? search}) async {
    emit(state.copyWith(status: PublicMarketsStatus.loading, search: search));

    final res = await api.list(search: search);
    if (res is! Success) {
      emit(
        state.copyWith(
          status: PublicMarketsStatus.failure,
          error: res is Failure ? res.message : 'خطای نامشخص',
        ),
      );
      return;
    }

    final data = res.response;
    emit(
      state.copyWith(
        status: PublicMarketsStatus.loaded,
        markets:
            data is List
                ? data
                    .whereType<Map>()
                    .map(
                      (e) => MarketModel.fromJson(Map<String, dynamic>.from(e)),
                    )
                    .toList()
                : const [],
      ),
    );
  }
}
