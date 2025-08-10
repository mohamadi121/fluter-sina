// Cart and Order API Client using Retrofit
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import '../core/models/dto/cart_dto.dart';

part 'cart_api_client.g.dart';

@RestApi()
abstract class CartApiClient {
  factory CartApiClient(Dio dio, {String baseUrl}) = _CartApiClient;

  /// Cart operations (ViewSet endpoints)
  @GET('/api/v1/user/orders')
  Future<OrderResponseDto> getCart();

  @POST('/api/v1/user/add_item')
  Future<CartItemResponseDto> addItem(@Body() CartItemDto item);

  @PUT('/api/v1/user/update_item/{itemId}')
  Future<CartItemResponseDto> updateItem(
    @Path() String itemId,
    @Body() CartUpdateItemDto item,
  );

  @DELETE('/api/v1/user/remove_item/{itemId}')
  Future<void> removeItem(@Path() String itemId);

  @POST('/api/v1/user/checkout')
  Future<OrderResponseDto> checkout();

  /// Order CRUD operations
  @POST('/api/v1/user/order/create')
  Future<OrderResponseDto> createOrder(@Body() OrderCreateDto order);

  @GET('/api/v1/user/order/list')
  Future<OrderListResponseDto> getOrders();

  @GET('/api/v1/user/order/{orderId}')
  Future<OrderResponseDto> getOrder(@Path() String orderId);

  @PUT('/api/v1/user/order/{orderId}/update')
  Future<OrderResponseDto> updateOrder(
    @Path() String orderId,
    @Body() OrderCreateDto order,
  );

  @DELETE('/api/v1/user/order/{orderId}/delete')
  Future<void> deleteOrder(@Path() String orderId);

  /// Owner endpoints for order management
  @PUT('/api/v1/owner/order/verify')
  Future<void> verifyOrder(@Body() OrderVerifyDto verification);

  @GET('/api/v1/owner/order/list')
  Future<OrderListResponseDto> getOwnerOrders();

  @GET('/api/v1/owner/order/{orderId}')
  Future<OrderResponseDto> getOwnerOrder(@Path() String orderId);
}
