part of 'public_markets_cubit.dart';

enum PublicMarketsStatus { initial, loading, loaded, failure }

class PublicMarketsState extends Equatable {
  final PublicMarketsStatus status;
  final List<MarketModel> markets;
  final String? search;
  final String? error;

  const PublicMarketsState({
    this.status = PublicMarketsStatus.initial,
    this.markets = const [],
    this.search,
    this.error,
  });

  PublicMarketsState copyWith({
    PublicMarketsStatus? status,
    List<MarketModel>? markets,
    String? search,
    String? error,
  }) {
    return PublicMarketsState(
      status: status ?? this.status,
      markets: markets ?? this.markets,
      search: search ?? this.search,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, markets, search, error];
}
