part of 'edit_market_cubit.dart';

enum EditMarketStatus { initial, loading, ready, saving, saved, failure }

class EditMarketState extends Equatable {
  final EditMarketStatus status;
  final String marketId;
  final Map<String, dynamic> market;
  final Map<String, dynamic>? contact;
  final Map<String, dynamic>? location;
  final String? error;

  const EditMarketState({
    this.status = EditMarketStatus.initial,
    this.marketId = '',
    this.market = const {},
    this.contact,
    this.location,
    this.error,
  });

  EditMarketState copyWith({
    EditMarketStatus? status,
    String? marketId,
    Map<String, dynamic>? market,
    Map<String, dynamic>? contact,
    Map<String, dynamic>? location,
    String? error,
  }) {
    return EditMarketState(
      status: status ?? this.status,
      marketId: marketId ?? this.marketId,
      market: market ?? this.market,
      contact: contact ?? this.contact,
      location: location ?? this.location,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    marketId,
    market,
    contact,
    location,
    error,
  ];
}
