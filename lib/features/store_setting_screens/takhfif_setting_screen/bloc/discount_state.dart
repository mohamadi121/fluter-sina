part of 'discount_cubit.dart';

enum DiscountStatus { initial, loading, loaded, saving, saved, failure }

class DiscountState extends Equatable {
  final DiscountStatus status;
  final List<Map<String, dynamic>> discounts;
  final String? error;

  const DiscountState({
    this.status = DiscountStatus.initial,
    this.discounts = const [],
    this.error,
  });

  DiscountState copyWith({
    DiscountStatus? status,
    List<Map<String, dynamic>>? discounts,
    String? error,
  }) {
    return DiscountState(
      status: status ?? this.status,
      discounts: discounts ?? this.discounts,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, discounts, error];
}
