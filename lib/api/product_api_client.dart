// Product API Client using Retrofit
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import '../core/models/dto/base_response_dto.dart';

part 'product_api_client.g.dart';

@RestApi()
abstract class ProductApiClient {
  factory ProductApiClient(Dio dio, {String baseUrl}) = _ProductApiClient;

  /// Owner product operations
  @GET('/api/v1/owner/product/list/')
  Future<BaseResponseDto<List<dynamic>>> getOwnerProducts();

  @GET('/api/v1/owner/product/{productId}/')
  Future<BaseResponseDto<dynamic>> getOwnerProduct(@Path() String productId);

  @POST('/api/v1/owner/product/create/')
  Future<BaseResponseDto<dynamic>> createProduct(@Body() Map<String, dynamic> product);

  @PUT('/api/v1/owner/product/update/{productId}/')
  Future<BaseResponseDto<dynamic>> updateProduct(
    @Path() String productId,
    @Body() Map<String, dynamic> product,
  );

  @DELETE('/api/v1/owner/product/delete/{productId}/')
  Future<void> deleteProduct(@Path() String productId);

  /// Product detail operations
  @GET('/api/v1/owner/product/detail/{productId}/')
  Future<BaseResponseDto<dynamic>> getProductDetail(@Path() String productId);
}
