// Market API Client using Retrofit
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import '../core/models/dto/market_dto.dart';
import '../core/models/dto/base_response_dto.dart';

part 'market_api_client.g.dart';

@RestApi()
abstract class MarketApiClient {
  factory MarketApiClient(Dio dio, {String baseUrl}) = _MarketApiClient;

  /// Owner market operations
  @POST('/api/v1/owner/market/create/')
  Future<MarketCreateResponseWrapperDto> createMarket(@Body() MarketCreateDto market);

  @GET('/api/v1/owner/market/list/')
  Future<MarketListResponseDto> getOwnerMarkets();

  @GET('/api/v1/owner/market/{marketId}/')
  Future<MarketResponseDto> getOwnerMarket(@Path() String marketId);

  @PUT('/api/v1/owner/market/update/{marketId}/')
  Future<MarketResponseDto> updateMarket(
    @Path() String marketId,
    @Body() MarketUpdateDto market,
  );

  @DELETE('/api/v1/owner/market/delete/{marketId}/')
  Future<void> deleteMarket(@Path() String marketId);

  /// Market status operations
  @PUT('/api/v1/owner/market/inactive/{marketId}/')
  Future<void> deactivateMarket(@Path() String marketId);

  @PUT('/api/v1/owner/market/queue/{marketId}/')
  Future<void> queueMarket(@Path() String marketId);

  /// Market location operations
  @POST('/api/v1/owner/market/location/create/')
  Future<MarketLocationResponseDto> createMarketLocation(@Body() MarketLocationCreateDto location);

  @GET('/api/v1/owner/market/location/list/{marketId}/')
  Future<BaseResponseDto<List<MarketLocationDto>>> getMarketLocations(@Path() String marketId);

  @PUT('/api/v1/owner/market/location/update/{locationId}/')
  Future<MarketLocationResponseDto> updateMarketLocation(
    @Path() String locationId,
    @Body() MarketLocationCreateDto location,
  );

  @DELETE('/api/v1/owner/market/location/delete/{locationId}/')
  Future<void> deleteMarketLocation(@Path() String locationId);

  /// Market media operations (simplified - multipart removed for build compatibility)
  // NOTE: File upload operations need to be implemented with custom Dio calls
  // due to build_runner/retrofit limitations with MultipartFile

  @DELETE('/api/v1/owner/market/logo/{marketId}/')
  Future<void> deleteMarketLogo(@Path() String marketId);

  @DELETE('/api/v1/owner/market/background/{marketId}/')
  Future<void> deleteMarketBackground(@Path() String marketId);

  /// Market slider operations (non-file operations only)
  @GET('/api/v1/owner/market/slider/{marketId}/')
  Future<BaseResponseDto<List<Map<String, dynamic>>>> getMarketSliders(@Path() String marketId);

  @DELETE('/api/v1/owner/market/slider/{sliderId}/')
  Future<void> deleteMarketSlider(@Path() String sliderId);

  /// Market theme operations
  @POST('/api/v1/owner/market/theme/{marketId}/')
  Future<void> setMarketTheme(
    @Path() String marketId,
    @Body() Map<String, dynamic> theme,
  );

  /// Market schedule operations
  @POST('/api/v1/owner/market/schedule/')
  Future<void> setMarketSchedule(@Body() Map<String, dynamic> schedule);

  /// Public market operations
  @GET('/api/v1/user/market/list/')
  Future<MarketListResponseDto> getMarkets({
    @Query('search') String? search,
    @Query('category') String? category,
    @Query('sub_category') String? subCategory,
    @Query('city') String? city,
    @Query('page') int? page,
  });

  @GET('/api/v1/user/market/{marketId}/')
  Future<MarketResponseDto> getMarket(@Path() String marketId);

  /// Market comments
  @GET('/api/v1/user/market/{marketId}/comments/')
  Future<BaseResponseDto<List<Map<String, dynamic>>>> getMarketComments(@Path() String marketId);

  @POST('/api/v1/user/market/{marketId}/comments/')
  Future<void> addMarketComment(
    @Path() String marketId,
    @Body() Map<String, dynamic> comment,
  );
}

// keep existing typedefs; will map responses via repositories using AppResult
