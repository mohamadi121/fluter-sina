import 'package:asoud/features/market/data/model/product_model.dart';
import 'package:asoud/features/market/presentation/blocs/add_product/add_product_bloc.dart';

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

  // Additional methods needed by AddProductBloc and MarketBloc
  Future<dynamic> listOwner(String marketId) async {}
  Future<dynamic> createDiscount(Map<String, dynamic> discountData) async {}
  Future<dynamic> create(dynamic dto) async {}
  Future<dynamic> listMarketThemes(String marketId) async {}
}
