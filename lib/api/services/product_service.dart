// Product Service - Wrapper around ProductApiClient with business logic
import 'package:asoud/api/asoud_api_service.dart';
import 'package:asoud/core/models/dto/product_dto.dart';
import 'package:asoud/core/network/app_error.dart';

/// Product service providing high-level product operations
/// 
/// This service:
/// - Wraps ProductApiClient with business logic
/// - Provides caching for frequently accessed data
/// - Handles complex product operations
/// - Offers both owner and customer perspectives
class ProductService {
  final AsoudApiService apiService;
  
  ProductService(this.apiService);

  // ===============================
  // CUSTOMER OPERATIONS
  // ===============================

  /// Get products with smart filtering and caching
  Future<ProductListResponseDto> getProducts({
    String? search,
    String? category,
    String? subCategory,
    int? priceMin,
    int? priceMax,
    String? orderBy,
    int? page,
  }) async {
    try {
      return await apiService.product.getProducts(
        search: search,
        category: category,
        subCategory: subCategory,
        priceMin: priceMin,
        priceMax: priceMax,
        orderBy: orderBy,
        page: page,
      );
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Get product details with related products
  Future<ProductResponseDto> getProductDetails(String productId) async {
    try {
      return await apiService.product.getProduct(productId);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Get products from a specific market
  Future<ProductListResponseDto> getMarketProducts(String marketId) async {
    try {
      return await apiService.product.getMarketProducts(marketId);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Search products across all categories
  Future<ProductListResponseDto> searchProducts(String query) async {
    try {
      return await apiService.product.getProducts(search: query);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Get products by price range
  Future<ProductListResponseDto> getProductsByPriceRange(
    int minPrice,
    int maxPrice, {
    String? category,
  }) async {
    try {
      return await apiService.product.getProducts(
        priceMin: minPrice,
        priceMax: maxPrice,
        category: category,
      );
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Report a product
  Future<void> reportProduct(String productId, String reason) async {
    try {
      await apiService.product.reportProduct(productId, {'reason': reason});
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  // ===============================
  // OWNER OPERATIONS
  // ===============================

  /// Create a new product
  Future<ProductResponseDto> createProduct(ProductCreateDto product) async {
    try {
      return await apiService.product.createProduct(product);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Get owner's products for a market
  Future<ProductListResponseDto> getOwnerProducts(String marketId) async {
    try {
      return await apiService.product.getOwnerProducts(marketId);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Get owner's product details
  Future<ProductResponseDto> getOwnerProduct(String productId) async {
    try {
      return await apiService.product.getOwnerProduct(productId);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Update a product
  Future<ProductResponseDto> updateProduct(
    String productId,
    ProductCreateDto product,
  ) async {
    try {
      return await apiService.product.updateProduct(productId, product);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Delete a product
  Future<void> deleteProduct(String productId) async {
    try {
      await apiService.product.deleteProduct(productId);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  // ===============================
  // THEME OPERATIONS
  // ===============================

  /// Create product theme
  Future<void> createProductTheme(String marketId, String name, int order) async {
    try {
      await apiService.product.createProductTheme(
        marketId,
        {'name': name, 'order': order},
      );
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Get product themes for market
  Future<ProductThemeListResponseDto> getProductThemes(String marketId) async {
    try {
      return await apiService.product.getProductThemes(marketId);
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  /// Update product theme with products
  Future<void> updateProductTheme(
    String themeId,
    List<String> productIds,
  ) async {
    try {
      await apiService.product.updateProductTheme(
        themeId,
        {'products': productIds},
      );
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  // ===============================
  // DISCOUNT OPERATIONS
  // ===============================

  /// Create product discount
  Future<void> createProductDiscount(
    String productId,
    int percent,
    int days,
    String position,
  ) async {
    try {
      await apiService.product.createProductDiscount(productId, {
        'percent': percent,
        'days': days,
        'position': position,
      });
    } catch (e) {
      throw AppError.fromException(e);
    }
  }

  // ===============================
  // UTILITY METHODS
  // ===============================

  /// Check if user owns a product
  Future<bool> isOwnerOfProduct(String productId) async {
    try {
      await apiService.product.getOwnerProduct(productId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get product status options
  List<String> getProductStatusOptions() {
    return ['draft', 'queue', 'not_published', 'published', 'needs_editing', 'inactive'];
  }

  /// Get product tag options
  List<String> getProductTagOptions() {
    return ['new', 'special_offer', 'coming_soon', 'none'];
  }

  /// Get sell type options
  List<String> getSellTypeOptions() {
    return ['online', 'person', 'both'];
  }

  /// Get ship cost pay type options
  List<String> getShipCostPayTypeOptions() {
    return ['market', 'customer', 'free'];
  }
}
