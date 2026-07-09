import 'package:asood/features/market/data/model/product_model.dart';
import 'package:asood/features/market/presentation/blocs/add_product/add_product_bloc.dart';

abstract class ProductRepository {
  Future<dynamic> productList(productId) async {}
  Future<dynamic> createProduct(ProductModel product) async {}
  Future<dynamic> createProductDiscount(
    productId,
    PositionEnum position,
    int percent,
    int days,
  ) async {}
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
  Future<dynamic> deleteMarketTheme(String themeId);
  Future<dynamic> getShipList(String productId);
  Future<dynamic> createShip(String productId, Map<String, dynamic> body);
}
