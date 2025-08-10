// Market DTOs for API layer
import 'package:json_annotation/json_annotation.dart';
import 'base_response_dto.dart';

part 'market_dto.g.dart';

@JsonSerializable()
class MarketDto {
  final String id;
  @JsonKey(name: 'business_id')
  final String businessId;
  final String name;
  @JsonKey(name: 'sub_category')
  final String subCategory;
  @JsonKey(name: 'sub_category_title')
  final String? subCategoryTitle;
  final String status;
  @JsonKey(name: 'is_paid')
  final bool isPaid;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'inactive_url')
  final String? inactiveUrl;
  @JsonKey(name: 'queue_url')
  final String? queueUrl;
  @JsonKey(name: 'logo_img')
  final String? logoImg;
  @JsonKey(name: 'background_img')
  final String? backgroundImg;
  final String? theme;
  @JsonKey(name: 'view_count')
  final int viewCount;
  final String? type;
  final String? description;
  @JsonKey(name: 'national_code')
  final String? nationalCode;
  final String? slogan;

  MarketDto({
    required this.id,
    required this.businessId,
    required this.name,
    required this.subCategory,
    this.subCategoryTitle,
    required this.status,
    required this.isPaid,
    required this.createdAt,
    this.inactiveUrl,
    this.queueUrl,
    this.logoImg,
    this.backgroundImg,
    this.theme,
    required this.viewCount,
    this.type,
    this.description,
    this.nationalCode,
    this.slogan,
  });

  factory MarketDto.fromJson(Map<String, dynamic> json) => _$MarketDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MarketDtoToJson(this);
}

@JsonSerializable()
class MarketCreateDto {
  final String type; // "company" or "individual"
  @JsonKey(name: 'business_id')
  final String businessId;
  final String name;
  final String description;
  @JsonKey(name: 'national_code')
  final String nationalCode;
  @JsonKey(name: 'sub_category')
  final String subCategory;
  final String slogan;

  MarketCreateDto({
    required this.type,
    required this.businessId,
    required this.name,
    required this.description,
    required this.nationalCode,
    required this.subCategory,
    required this.slogan,
  });

  factory MarketCreateDto.fromJson(Map<String, dynamic> json) => _$MarketCreateDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MarketCreateDtoToJson(this);
}

@JsonSerializable()
class MarketCreateResponseDto {
  final String market;
  final String type;
  @JsonKey(name: 'business_id')
  final String businessId;
  final String name;
  final String description;
  @JsonKey(name: 'national_code')
  final String nationalCode;
  @JsonKey(name: 'sub_category')
  final String subCategory;
  final String slogan;

  MarketCreateResponseDto({
    required this.market,
    required this.type,
    required this.businessId,
    required this.name,
    required this.description,
    required this.nationalCode,
    required this.subCategory,
    required this.slogan,
  });

  factory MarketCreateResponseDto.fromJson(Map<String, dynamic> json) => _$MarketCreateResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MarketCreateResponseDtoToJson(this);
}

@JsonSerializable()
class MarketUpdateDto {
  final String? type;
  @JsonKey(name: 'business_id')
  final String? businessId;
  final String? name;
  final String? description;
  @JsonKey(name: 'sub_category')
  final String? subCategory;
  final String? slogan;

  MarketUpdateDto({
    this.type,
    this.businessId,
    this.name,
    this.description,
    this.subCategory,
    this.slogan,
  });

  factory MarketUpdateDto.fromJson(Map<String, dynamic> json) => _$MarketUpdateDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MarketUpdateDtoToJson(this);
}

@JsonSerializable()
class MarketLocationDto {
  final String id;
  final String market;
  final String city;
  final String address;
  @JsonKey(name: 'zip_code')
  final String zipCode;
  final String latitude;
  final String longitude;

  MarketLocationDto({
    required this.id,
    required this.market,
    required this.city,
    required this.address,
    required this.zipCode,
    required this.latitude,
    required this.longitude,
  });

  factory MarketLocationDto.fromJson(Map<String, dynamic> json) => _$MarketLocationDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MarketLocationDtoToJson(this);
}

@JsonSerializable()
class MarketLocationCreateDto {
  final String market;
  final String city;
  final String address;
  @JsonKey(name: 'zip_code')
  final String zipCode;
  final String latitude;
  final String longitude;

  MarketLocationCreateDto({
    required this.market,
    required this.city,
    required this.address,
    required this.zipCode,
    required this.latitude,
    required this.longitude,
  });

  factory MarketLocationCreateDto.fromJson(Map<String, dynamic> json) => _$MarketLocationCreateDtoFromJson(json);
  Map<String, dynamic> toJson() => _$MarketLocationCreateDtoToJson(this);
}

// Response DTOs
typedef MarketResponseDto = BaseResponseDto<MarketDto>;
typedef MarketListResponseDto = BaseResponseDto<List<MarketDto>>;
typedef MarketCreateResponseWrapperDto = BaseResponseDto<MarketCreateResponseDto>;
typedef MarketLocationResponseDto = BaseResponseDto<MarketLocationDto>;
