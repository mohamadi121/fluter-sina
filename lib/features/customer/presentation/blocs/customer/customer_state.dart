part of 'customer_bloc.dart';

class CustomerState {
  final UiStatus status;
  final List<MarketModel>? markets;
  final List<CustomerReqModel>? request;
  final List? orders;
  const CustomerState({
    required this.status,
    this.markets,
    this.request,
    this.orders,
  });

  factory CustomerState.initial() => const CustomerState(
    status: UiIdle(),
    markets: [],
    request: [],
    orders: [],
  );

  CustomerState copyWith({
    UiStatus? status,
    List<MarketModel>? markets,
    List<CustomerReqModel>? request,
    List? orders,
  }) {
    return CustomerState(
      status: status ?? this.status,
      markets: markets ?? this.markets,
      request: request ?? this.request,
      orders: orders ?? this.orders,
    );
  }
}
