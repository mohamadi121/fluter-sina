import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/create_workspace/domain/repository/create_market_repository.dart';

part 'edit_market_state.dart';

/// Loads and saves the owner's market info (basic / contact / location).
/// All backend endpoints are keyed by the market id.
class EditMarketCubit extends Cubit<EditMarketState> {
  final CreateMarketRepository repo;

  EditMarketCubit({required this.repo}) : super(const EditMarketState());

  Future<void> load(String marketId) async {
    emit(state.copyWith(status: EditMarketStatus.loading, marketId: marketId));

    final marketRes = await repo.getMarket(marketId);
    if (marketRes is! Success) {
      emit(
        state.copyWith(
          status: EditMarketStatus.failure,
          error:
              marketRes is Failure
                  ? marketRes.message
                  : 'خطا در دریافت اطلاعات',
        ),
      );
      return;
    }

    // Contact and location may not exist yet for a fresh market — tolerate.
    final contactRes = await repo.getMarketContact(marketId);
    final locationRes = await repo.getMarketLocation(marketId);

    emit(
      state.copyWith(
        status: EditMarketStatus.ready,
        market: _asMap(marketRes.response),
        contact: contactRes is Success ? _asMap(contactRes.response) : null,
        location: locationRes is Success ? _asMap(locationRes.response) : null,
      ),
    );
  }

  Future<void> saveBasic(Map<String, dynamic> body) =>
      _save(() => repo.updateMarket(state.marketId, body));

  Future<void> saveContact(Map<String, dynamic> body) =>
      _save(() => repo.updateMarketContact(state.marketId, body));

  Future<void> saveLocation(Map<String, dynamic> body) =>
      _save(() => repo.updateMarketLocation(state.marketId, body));

  Future<void> _save(Future<dynamic> Function() call) async {
    emit(state.copyWith(status: EditMarketStatus.saving));
    final res = await call();
    if (res is Success) {
      emit(state.copyWith(status: EditMarketStatus.saved));
      return;
    }
    emit(
      state.copyWith(
        status: EditMarketStatus.failure,
        error: res is Failure ? res.message : 'ذخیره ناموفق بود',
      ),
    );
  }

  Map<String, dynamic> _asMap(dynamic data) =>
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
}
