import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import '../core/models/dto/base_response_dto.dart';
import '../core/models/dto/auth_dto.dart';

part 'auth_api_client.g.dart';

@RestApi()
abstract class AuthApiClient {
  factory AuthApiClient(Dio dio, {String baseUrl}) = _AuthApiClient;

  /// Create PIN for mobile number
  @POST('/user/pin/create/')
  @MultiPart()
  Future<BaseResponseDto<EmptyDto>> createPin(
    @Part(name: 'mobile_number') String mobileNumber,
  );

  /// Verify PIN and get token
  @POST('/user/pin/verify/')
  @MultiPart()
  Future<BaseResponseDto<TokenResponseDto>> verifyPin(
    @Part(name: 'mobile_number') String mobileNumber,
    @Part(name: 'pin') String pin,
  );
}
