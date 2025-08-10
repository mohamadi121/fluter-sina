// User API Client using Retrofit
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import '../core/models/dto/base_response_dto.dart';

part 'user_api_client.g.dart';

@RestApi()
abstract class UserApiClient {
  factory UserApiClient(Dio dio, {String baseUrl}) = _UserApiClient;

  /// User profile operations
  @GET('/api/v1/user/profile/')
  Future<BaseResponseDto<dynamic>> getUserProfile();

  @PUT('/api/v1/user/profile/update/')
  Future<BaseResponseDto<dynamic>> updateUserProfile(@Body() Map<String, dynamic> profile);

  /// User bank info operations
  @GET('/api/v1/user/bank/info/list/')
  Future<BaseResponseDto<List<dynamic>>> getUserBankInfo();

  @POST('/api/v1/user/bank/info/create/')
  Future<BaseResponseDto<dynamic>> createUserBankInfo(@Body() Map<String, dynamic> bankInfo);

  @GET('/api/v1/user/bank/info/detail/{pk}/')
  Future<BaseResponseDto<dynamic>> getUserBankInfoDetail(@Path() String pk);

  @PUT('/api/v1/user/bank/info/update/{pk}/')
  Future<BaseResponseDto<dynamic>> updateUserBankInfo(
    @Path() String pk,
    @Body() Map<String, dynamic> bankInfo,
  );

  @DELETE('/api/v1/user/bank/info/delete/{pk}/')
  Future<void> deleteUserBankInfo(@Path() String pk);

  /// User PIN operations
  @POST('/api/v1/user/pin/create/')
  Future<BaseResponseDto<dynamic>> createUserPin(@Body() Map<String, dynamic> pinData);

  @POST('/api/v1/user/pin/verify/')
  Future<BaseResponseDto<dynamic>> verifyUserPin(@Body() Map<String, dynamic> pinData);

  /// Market bookmarks
  @GET('/api/v1/user/market/bookmark/')
  Future<BaseResponseDto<List<dynamic>>> getUserBookmarks();
}
