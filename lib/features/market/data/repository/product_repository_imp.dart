import 'package:asoud/features/market/data/data_source/product_api_service.dart';
import 'package:asoud/features/market/data/model/product_model.dart';
import 'package:asoud/features/market/domain/repository/product_repository.dart';
import 'package:asoud/features/market/presentation/blocs/add_product/add_product_bloc.dart';

class ProductRepositoryImp implements ProductRepository {
  final ProductApiService productApiService;
  ProductRepositoryImp(this.productApiService);
  @override
  Future createProduct(ProductModel product) async {
    return await productApiService.createProduct(product);
  }

  @override
  Future createProductDiscount(
    productId,
    PositionEnum position,
    int percent,
    int days,
  ) async {
    return await productApiService.createProductDiscount(
      productId,
      position,
      percent,
      days,
    );
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
  Future listOwner(String marketId) async {
    // TODO: Implement listOwner functionality
    return [];
  }

  @override
  Future createDiscount(Map<String, dynamic> discountData) async {
    // TODO: Implement createDiscount functionality
    return true;
  }

  @override
  Future create(dynamic dto) async {
    // TODO: Implement create functionality
    return true;
  }

  @override
  Future listMarketThemes(String marketId) async {
    // TODO: Implement listMarketThemes functionality
    return [];
  }
}
