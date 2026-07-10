part of 'affiliate_cubit.dart';

enum AffiliateStatus { initial, loading, loaded, creating, failure }

class AffiliateState extends Equatable {
  final AffiliateStatus status;
  final List<Map<String, dynamic>> products;
  final String? error;

  const AffiliateState({
    this.status = AffiliateStatus.initial,
    this.products = const [],
    this.error,
  });

  AffiliateState copyWith({
    AffiliateStatus? status,
    List<Map<String, dynamic>>? products,
    String? error,
  }) {
    return AffiliateState(
      status: status ?? this.status,
      products: products ?? this.products,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, products, error];
}
