part of 'product_detail_cubit.dart';

enum ProductDetailStatus { initial, loading, ready, failure }

class ProductDetailState extends Equatable {
  final ProductDetailStatus status;
  final String productId;
  final Map<String, dynamic> detail;
  final List<Map<String, dynamic>> comments;
  final bool sendingComment;
  final bool commentSent;
  final String? error;

  const ProductDetailState({
    this.status = ProductDetailStatus.initial,
    this.productId = '',
    this.detail = const {},
    this.comments = const [],
    this.sendingComment = false,
    this.commentSent = false,
    this.error,
  });

  ProductDetailState copyWith({
    ProductDetailStatus? status,
    String? productId,
    Map<String, dynamic>? detail,
    List<Map<String, dynamic>>? comments,
    bool? sendingComment,
    bool? commentSent,
    String? error,
  }) {
    return ProductDetailState(
      status: status ?? this.status,
      productId: productId ?? this.productId,
      detail: detail ?? this.detail,
      comments: comments ?? this.comments,
      sendingComment: sendingComment ?? this.sendingComment,
      commentSent: commentSent ?? this.commentSent,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    productId,
    detail,
    comments,
    sendingComment,
    commentSent,
    error,
  ];
}
