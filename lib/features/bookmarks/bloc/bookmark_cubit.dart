import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/core/models/market_model.dart';
import 'package:asood/features/bookmarks/data/bookmark_api_service.dart';

part 'bookmark_state.dart';

class BookmarkCubit extends Cubit<BookmarkState> {
  final BookmarkApiService api;

  BookmarkCubit({required this.api}) : super(const BookmarkState());

  Future<void> load() async {
    emit(state.copyWith(status: BookmarkStatus.loading));

    final res = await api.list();
    if (res is! Success) {
      emit(
        state.copyWith(
          status: BookmarkStatus.failure,
          error: res is Failure ? res.message : 'خطای نامشخص',
        ),
      );
      return;
    }

    final data = res.response;
    final markets =
        data is List
            ? data
                .whereType<Map>()
                .map((e) => MarketModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : <MarketModel>[];
    emit(
      state.copyWith(
        status: BookmarkStatus.loaded,
        markets: markets,
        bookmarkedIds: markets.map((m) => m.id.toString()).toSet(),
      ),
    );
  }

  Future<void> toggle(String marketId) async {
    if (state.pendingIds.contains(marketId)) return;

    final wasBookmarked = state.bookmarkedIds.contains(marketId);
    final desired = !wasBookmarked;
    final originalMarkets = state.markets;
    final removedIndex = originalMarkets.indexWhere(
      (market) => market.id.toString() == marketId,
    );
    final removedMarket =
        removedIndex == -1 ? null : originalMarkets[removedIndex];
    final pending = Set<String>.from(state.pendingIds)..add(marketId);
    emit(
      state.copyWith(
        markets:
            desired
                ? originalMarkets
                : originalMarkets
                    .where((market) => market.id.toString() != marketId)
                    .toList(),
        bookmarkedIds: _flipped(marketId, desired),
        pendingIds: pending,
        error: null,
      ),
    );

    final res = await api.setBookmarked(marketId, desired);
    final settledPending = Set<String>.from(state.pendingIds)..remove(marketId);
    if (res is! Success) {
      emit(
        state.copyWith(
          markets:
              desired
                  ? state.markets
                  : _restoredMarket(state.markets, removedMarket, removedIndex),
          bookmarkedIds: _flipped(marketId, wasBookmarked),
          pendingIds: settledPending,
          error: res is Failure ? res.message : 'خطای نامشخص',
        ),
      );
      return;
    }

    final data = res.response;
    final authoritative =
        data is Map && data['bookmarked'] is bool
            ? data['bookmarked'] as bool
            : desired;
    emit(
      state.copyWith(
        markets:
            authoritative
                ? _restoredMarket(state.markets, removedMarket, removedIndex)
                : state.markets
                    .where((market) => market.id.toString() != marketId)
                    .toList(),
        bookmarkedIds: _flipped(marketId, authoritative),
        pendingIds: settledPending,
        error: null,
      ),
    );
  }

  Set<String> _flipped(String marketId, bool bookmarked) {
    final ids = Set<String>.from(state.bookmarkedIds);
    if (bookmarked) {
      ids.add(marketId);
    } else {
      ids.remove(marketId);
    }
    return ids;
  }

  List<MarketModel> _restoredMarket(
    List<MarketModel> current,
    MarketModel? market,
    int originalIndex,
  ) {
    if (market == null ||
        current.any((item) => item.id.toString() == market.id.toString())) {
      return current;
    }
    final restored = List<MarketModel>.from(current);
    restored.insert(originalIndex.clamp(0, restored.length), market);
    return restored;
  }
}
