part of 'owner_orders_cubit.dart';

enum OwnerOrdersStatus { initial, loading, loaded, failure }

class OwnerOrdersState extends Equatable {
  final OwnerOrdersStatus status;
  final List<Map<String, dynamic>> orders;
  final String? error;

  const OwnerOrdersState({
    this.status = OwnerOrdersStatus.initial,
    this.orders = const [],
    this.error,
  });

  OwnerOrdersState copyWith({
    OwnerOrdersStatus? status,
    List<Map<String, dynamic>>? orders,
    String? error,
  }) {
    return OwnerOrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, orders, error];
}
