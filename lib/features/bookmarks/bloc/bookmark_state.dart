part of 'bookmark_cubit.dart';

enum BookmarkStatus { initial, loading, loaded, failure }

class BookmarkState extends Equatable {
  final BookmarkStatus status;
  final List<MarketModel> markets;
  final Set<String> bookmarkedIds;
  final String? error;

  const BookmarkState({
    this.status = BookmarkStatus.initial,
    this.markets = const [],
    this.bookmarkedIds = const {},
    this.error,
  });

  bool isBookmarked(String marketId) => bookmarkedIds.contains(marketId);

  BookmarkState copyWith({
    BookmarkStatus? status,
    List<MarketModel>? markets,
    Set<String>? bookmarkedIds,
    String? error,
  }) {
    return BookmarkState(
      status: status ?? this.status,
      markets: markets ?? this.markets,
      bookmarkedIds: bookmarkedIds ?? this.bookmarkedIds,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, markets, bookmarkedIds, error];
}
