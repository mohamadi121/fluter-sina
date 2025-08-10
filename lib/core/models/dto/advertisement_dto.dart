// Advertisement DTOs for API layer
import 'package:json_annotation/json_annotation.dart';
import 'base_response_dto.dart';

part 'advertisement_dto.g.dart';

@JsonSerializable()
class AdvertisementDto {
  final String id;
  final dynamic product;
  final AdvertisementUserDto user;
  final List<AdvertisementImageDto> images;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  final String type;
  final String name;
  final String description;
  final String? email;
  final String price;
  @JsonKey(name: 'is_paid')
  final bool isPaid;
  final String category;
  final String province;
  final String city;
  final List<String> keywords;

  AdvertisementDto({
    required this.id,
    this.product,
    required this.user,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
    required this.name,
    required this.description,
    this.email,
    required this.price,
    required this.isPaid,
    required this.category,
    required this.province,
    required this.city,
    required this.keywords,
  });

  factory AdvertisementDto.fromJson(Map<String, dynamic> json) => _$AdvertisementDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AdvertisementDtoToJson(this);
}

@JsonSerializable()
class AdvertisementUserDto {
  final String id;
  @JsonKey(name: 'mobile_number')
  final String mobileNumber;

  AdvertisementUserDto({
    required this.id,
    required this.mobileNumber,
  });

  factory AdvertisementUserDto.fromJson(Map<String, dynamic> json) => _$AdvertisementUserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AdvertisementUserDtoToJson(this);
}

@JsonSerializable()
class AdvertisementImageDto {
  final String id;
  final String image;

  AdvertisementImageDto({
    required this.id,
    required this.image,
  });

  factory AdvertisementImageDto.fromJson(Map<String, dynamic> json) => _$AdvertisementImageDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AdvertisementImageDtoToJson(this);
}

@JsonSerializable()
class AdvertisementListItemDto {
  final String id;
  final String name;
  final AdvertisementCategoryDto category;
  final String price;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  final List<AdvertisementImageDto> images;

  AdvertisementListItemDto({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.updatedAt,
    required this.images,
  });

  factory AdvertisementListItemDto.fromJson(Map<String, dynamic> json) => _$AdvertisementListItemDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AdvertisementListItemDtoToJson(this);
}

@JsonSerializable()
class AdvertisementCategoryDto {
  final String id;
  final String title;

  AdvertisementCategoryDto({
    required this.id,
    required this.title,
  });

  factory AdvertisementCategoryDto.fromJson(Map<String, dynamic> json) => _$AdvertisementCategoryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AdvertisementCategoryDtoToJson(this);
}

@JsonSerializable()
class AdvertisementCreateDto {
  final String type; // "good" or "service"
  final String name;
  final String description;
  final String category;
  final String province;
  final String city;
  final String? email;
  final List<String> keywords;
  final int price;
  // Note: images would be handled separately as multipart/form-data

  AdvertisementCreateDto({
    required this.type,
    required this.name,
    required this.description,
    required this.category,
    required this.province,
    required this.city,
    this.email,
    required this.keywords,
    required this.price,
  });

  factory AdvertisementCreateDto.fromJson(Map<String, dynamic> json) => _$AdvertisementCreateDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AdvertisementCreateDtoToJson(this);
}

@JsonSerializable()
class AdvertisementUpdateDto {
  final String? type;
  final String? name;
  final String? description;
  final String? category;
  final String? province;
  final String? city;
  final String? email;
  final List<String>? keywords;
  final int? price;

  AdvertisementUpdateDto({
    this.type,
    this.name,
    this.description,
    this.category,
    this.province,
    this.city,
    this.email,
    this.keywords,
    this.price,
  });

  factory AdvertisementUpdateDto.fromJson(Map<String, dynamic> json) => _$AdvertisementUpdateDtoFromJson(json);
  Map<String, dynamic> toJson() => _$AdvertisementUpdateDtoToJson(this);
}

// Response DTOs
typedef AdvertisementResponseDto = BaseResponseDto<AdvertisementDto>;
typedef AdvertisementListResponseDto = BaseResponseDto<List<AdvertisementListItemDto>>;
typedef AdvertisementSelfListResponseDto = BaseResponseDto<List<AdvertisementListItemDto>>;
