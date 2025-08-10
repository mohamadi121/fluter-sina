// Payment DTOs for API layer
import 'package:json_annotation/json_annotation.dart';
import 'base_response_dto.dart';

part 'payment_dto.g.dart';

@JsonSerializable()
class PaymentDto {
  final String id;
  final String amount;
  final PaymentTargetDto target;
  @JsonKey(name: 'target_id')
  final String targetId;
  @JsonKey(name: 'target_content')
  final String targetContent;
  final PaymentGatewayDto gateway;

  PaymentDto({
    required this.id,
    required this.amount,
    required this.target,
    required this.targetId,
    required this.targetContent,
    required this.gateway,
  });

  factory PaymentDto.fromJson(Map<String, dynamic> json) => _$PaymentDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentDtoToJson(this);
}

@JsonSerializable()
class PaymentTargetDto {
  final String id;
  final dynamic product;
  final PaymentUserDto user;
  final List<dynamic> images;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  final String type;
  final String name;
  final String description;
  final String? email;
  final String? price;
  @JsonKey(name: 'is_paid')
  final bool isPaid;
  final String? category;
  final String? province;
  final String? city;
  final List<String> keywords;

  PaymentTargetDto({
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
    this.price,
    required this.isPaid,
    this.category,
    this.province,
    this.city,
    required this.keywords,
  });

  factory PaymentTargetDto.fromJson(Map<String, dynamic> json) => _$PaymentTargetDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentTargetDtoToJson(this);
}

@JsonSerializable()
class PaymentUserDto {
  final String id;
  @JsonKey(name: 'mobile_number')
  final String mobileNumber;

  PaymentUserDto({
    required this.id,
    required this.mobileNumber,
  });

  factory PaymentUserDto.fromJson(Map<String, dynamic> json) => _$PaymentUserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentUserDtoToJson(this);
}

@JsonSerializable()
class PaymentGatewayDto {
  final String id;
  final String name;

  PaymentGatewayDto({
    required this.id,
    required this.name,
  });

  factory PaymentGatewayDto.fromJson(Map<String, dynamic> json) => _$PaymentGatewayDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentGatewayDtoToJson(this);
}

@JsonSerializable()
class PaymentCreateDto {
  final String target; // "advertisement", "wallet", "order", "market"
  @JsonKey(name: 'target_id')
  final String targetId;
  final int amount;

  PaymentCreateDto({
    required this.target,
    required this.targetId,
    required this.amount,
  });

  factory PaymentCreateDto.fromJson(Map<String, dynamic> json) => _$PaymentCreateDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentCreateDtoToJson(this);
}

@JsonSerializable()
class PaymentCreateResponseDto {
  final String id;

  PaymentCreateResponseDto({
    required this.id,
  });

  factory PaymentCreateResponseDto.fromJson(Map<String, dynamic> json) => _$PaymentCreateResponseDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentCreateResponseDtoToJson(this);
}

@JsonSerializable()
class PaymentListItemDto {
  final String id;
  final String amount;
  final String status;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'target_content')
  final String targetContent;

  PaymentListItemDto({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    required this.targetContent,
  });

  factory PaymentListItemDto.fromJson(Map<String, dynamic> json) => _$PaymentListItemDtoFromJson(json);
  Map<String, dynamic> toJson() => _$PaymentListItemDtoToJson(this);
}

// Response DTOs
typedef PaymentResponseDto = BaseResponseDto<PaymentDto>;
typedef PaymentCreateResponseWrapperDto = BaseResponseDto<PaymentCreateResponseDto>;
typedef PaymentListResponseDto = BaseResponseDto<List<PaymentListItemDto>>;
