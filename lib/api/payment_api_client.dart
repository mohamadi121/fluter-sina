// Payment API Client using Retrofit
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import '../core/models/dto/payment_dto.dart';

part 'payment_api_client.g.dart';

@RestApi()
abstract class PaymentApiClient {
  factory PaymentApiClient(Dio dio, {String baseUrl}) = _PaymentApiClient;

  /// Payment operations
  @POST('/api/v1/user/payments/create/')
  Future<PaymentCreateResponseWrapperDto> createPayment(@Body() PaymentCreateDto payment);

  @GET('/api/v1/user/payments/')
  Future<PaymentListResponseDto> getPayments();

  @GET('/api/v1/user/payments/{paymentId}/')
  Future<PaymentResponseDto> getPayment(@Path() String paymentId);

  /// Payment gateway operations
  @GET('/api/v1/user/payments/pay')
  Future<void> redirectToPayment(@Query('id') String paymentId);

  @GET('/api/v1/user/payments/verify/')
  Future<PaymentResponseDto> verifyPayment({
    @Query('Authority') String? authority,
    @Query('Status') String? status,
  });

  /// Advertisement payment
  @GET('/api/v1/advertisements/payment')
  Future<PaymentResponseDto> getAdvertisementPayment(@Query('advertisement') String adId);
}
