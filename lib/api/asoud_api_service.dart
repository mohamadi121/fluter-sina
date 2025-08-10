// Unified API Service - Central point for all API clients
import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import 'auth_api_client.dart';
import 'category_api_client.dart';
import 'product_api_client.dart';
import 'cart_api_client.dart';
import 'payment_api_client.dart';
import 'user_api_client.dart';
import 'market_api_client.dart';
import 'advertisement_api_client.dart';

/// Central API service that provides access to all typed API clients
/// This replaces the scattered legacy API services with a unified, type-safe interface
class AsoudApiService {
  late final AuthApiClient auth;
  late final CategoryApiClient category;
  late final ProductApiClient product;
  late final CartApiClient cart;
  late final PaymentApiClient payment;
  late final UserApiClient user;
  late final MarketApiClient market;
  late final AdvertisementApiClient advertisement;

  AsoudApiService(DioClient dioClient) {
    final Dio dio = dioClient.dio;
    
    // Initialize all typed API clients with the shared Dio instance
    auth = AuthApiClient(dio);
    category = CategoryApiClient(dio);
    product = ProductApiClient(dio);
    cart = CartApiClient(dio);
    payment = PaymentApiClient(dio);
    user = UserApiClient(dio);
    market = MarketApiClient(dio);
    advertisement = AdvertisementApiClient(dio);
  }
}

/// Factory for creating AsoudApiService instances
/// This can be used for dependency injection
class ApiServiceFactory {
  static AsoudApiService create(DioClient dioClient) {
    return AsoudApiService(dioClient);
  }
}
