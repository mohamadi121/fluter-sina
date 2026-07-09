import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/market/domain/repository/product_repository.dart';

part 'product_detail_state.dart';

/// Product detail page state: owner product detail + its comment thread.
/// Detail: GET owner/product/detail/{id}/ (envelope).
/// Comments: GET user/comment/comments/product/{id}/ (bare list).
/// Comment create: POST user/comment/create/ (bare {"message","id"}, 201).
class ProductDetailCubit extends Cubit<ProductDetailState> {
  final ProductRepository repo;

  ProductDetailCubit({required this.repo}) : super(const ProductDetailState());

  Future<void> load(String productId) async {
    emit(
      state.copyWith(status: ProductDetailStatus.loading, productId: productId),
    );

    final detailRes = await repo.getProductDetail(productId);
    if (detailRes is! Success) {
      emit(
        state.copyWith(
          status: ProductDetailStatus.failure,
          error:
              detailRes is Failure ? detailRes.message : 'خطا در دریافت محصول',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: ProductDetailStatus.ready,
        detail:
            detailRes.response is Map
                ? Map<String, dynamic>.from(detailRes.response as Map)
                : const {},
      ),
    );
    await refreshComments();
  }

  Future<void> refreshComments() async {
    final res = await repo.getProductComments(state.productId);
    if (res is Success && res.response is List) {
      emit(
        state.copyWith(
          comments:
              (res.response as List)
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList(),
        ),
      );
    }
  }

  Future<void> sendComment(String text, {int? parentId}) async {
    if (text.trim().isEmpty) {
      return;
    }
    emit(state.copyWith(sendingComment: true));

    final res = await repo.createComment(
      contentType: 'product',
      objectId: state.productId,
      comment: text.trim(),
      parentId: parentId,
    );

    if (res is Success) {
      await refreshComments();
      emit(state.copyWith(sendingComment: false, commentSent: true));
      emit(state.copyWith(sendingComment: false, commentSent: false));
      return;
    }
    emit(
      state.copyWith(
        sendingComment: false,
        error: res is Failure ? res.message : 'ارسال نظر ناموفق بود',
      ),
    );
  }
}
