import 'package:asood/features/market/data/data_source/product_api_service.dart';
import 'package:asood/features/market/data/model/product_model.dart';
import 'package:asood/features/market/domain/repository/product_repository.dart';

class ProductRepositoryImp implements ProductRepository {
  final ProductApiService productApiService;
  ProductRepositoryImp(this.productApiService);
  @override
  Future createProduct(ProductModel product) async {
    return await productApiService.createProduct(product);
  }

  @override
  Future createMarketTheme(String marketId, int order) async {
    return await productApiService.createMarketTheme(marketId, order);
  }

  @override
  Future getMarketTheme(String marketId) async {
    return await productApiService.getMarketTheme(marketId);
  }

  @override
  Future productList(productId) async {
    return await productApiService.getProducts(productId);
  }

  @override
  Future updateMarketTheme({
    required String productId,
    required String themeId,
    required String themeIndex,
  }) async {
    return await productApiService.updateMarketTheme(
      productId,
      themeId,
      themeIndex,
    );
  }

  @override
  Future getProductDetail(String productId) {
    return productApiService.getProductById(productId);
  }

  @override
  Future getProductComments(String productId) {
    return productApiService.getProductComments(productId);
  }

  @override
  Future createComment({
    required String contentType,
    required String objectId,
    required String comment,
    int? parentId,
  }) {
    return productApiService.createComment(
      contentType: contentType,
      objectId: objectId,
      comment: comment,
      parentId: parentId,
    );
  }

  @override
  Future deleteMarketTheme(String themeId) {
    return productApiService.deleteMarketTheme(themeId);
  }
}
