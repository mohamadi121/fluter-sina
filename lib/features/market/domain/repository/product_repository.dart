import 'package:asood/features/market/data/model/product_model.dart';

abstract class ProductRepository {
  Future<dynamic> productList(productId) async {}
  Future<dynamic> createProduct(ProductModel product) async {}
  Future<dynamic> createMarketTheme(String marketId, int order) async {}
  Future<dynamic> getMarketTheme(String marketId) async {}
  Future<dynamic> updateMarketTheme({
    required String productId,
    required String themeId,
    required String themeIndex,
  }) async {}
  Future<dynamic> getProductDetail(String productId);
  Future<dynamic> getProductComments(String productId);
  Future<dynamic> createComment({
    required String contentType,
    required String objectId,
    required String comment,
    int? parentId,
  });
}
