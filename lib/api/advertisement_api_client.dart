// Advertisement API Client using Retrofit
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import '../core/models/dto/advertisement_dto.dart';

part 'advertisement_api_client.g.dart';

@RestApi()
abstract class AdvertisementApiClient {
  factory AdvertisementApiClient(Dio dio, {String baseUrl}) = _AdvertisementApiClient;

  /// Advertisement CRUD operations
  @POST('/api/v1/advertisements/create')
  @MultiPart()
  Future<AdvertisementResponseDto> createAdvertisement(
    @Part() String type,
    @Part() String name,
    @Part() String description,
    @Part() String category,
    @Part() String province,
    @Part() String city,
    @Part() String? email,
    @Part() List<String> keywords,
    @Part() int price,
    @Part() List<MultipartFile>? images,
  );

  @GET('/api/v1/advertisements/')
  Future<AdvertisementListResponseDto> getAdvertisements({
    @Query('search') String? search,
    @Query('category') String? category,
    @Query('province') String? province,
    @Query('city') String? city,
    @Query('type') String? type,
    @Query('price_min') int? priceMin,
    @Query('price_max') int? priceMax,
    @Query('order_by') String? orderBy,
    @Query('page') int? page,
  });

  @GET('/api/v1/advertisements/{adId}')
  Future<AdvertisementResponseDto> getAdvertisement(@Path() String adId);

  @GET('/api/v1/advertisements/self')
  Future<AdvertisementSelfListResponseDto> getSelfAdvertisements();

  @PUT('/api/v1/advertisements/{adId}/update')
  @MultiPart()
  Future<AdvertisementResponseDto> updateAdvertisement(
    @Path() String adId,
    @Part() String? type,
    @Part() String? name,
    @Part() String? description,
    @Part() String? category,
    @Part() String? province,
    @Part() String? city,
    @Part() String? email,
    @Part() List<String>? keywords,
    @Part() int? price,
    @Part() List<MultipartFile>? images,
  );

  @DELETE('/api/v1/advertisements/{adId}/delete')
  Future<void> deleteAdvertisement(@Path() String adId);

  /// Advertisement payment
  @GET('/api/v1/advertisements/payment')
  Future<BaseResponseDto<Map<String, dynamic>>> getAdvertisementPayment(@Query('advertisement') String adId);
}

typedef BaseResponseDto<T> = AdvertisementResponseDto;
