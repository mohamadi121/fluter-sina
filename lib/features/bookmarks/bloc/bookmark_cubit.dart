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
    final wasBookmarked = state.bookmarkedIds.contains(marketId);
    // Optimistic flip; reverted if the call fails.
    emit(state.copyWith(bookmarkedIds: _flipped(marketId, !wasBookmarked)));

    final res = await api.toggle(marketId);
    if (res is! Success) {
      emit(
        state.copyWith(
          bookmarkedIds: _flipped(marketId, wasBookmarked),
          error: res is Failure ? res.message : 'خطای نامشخص',
        ),
      );
    }
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
}
