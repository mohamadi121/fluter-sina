import 'package:asood/core/architecture/result.dart';
import 'package:asood/features/market/data/model/product_model.dart';
import 'package:asood/features/market/presentation/blocs/add_product/add_product_bloc.dart';

abstract class ProductRepository {
  Future<Result<List<dynamic>>> productList(String productId);
  
  Future<Result<Map<String, dynamic>>> createProduct(ProductModel product);
  
  Future<Result<Map<String, dynamic>>> createProductDiscount(
    String productId,
    PositionEnum position,
    int percent,
    int days,
  );
  
  Future<Result<Map<String, dynamic>>> createMarketTheme(String marketId, int order);
  
  Future<Result<Map<String, dynamic>>> getMarketTheme(String marketId);
  
  Future<Result<Map<String, dynamic>>> updateMarketTheme({
    required String productId,
    required String themeId,
    required String themeIndex,
  });
}
