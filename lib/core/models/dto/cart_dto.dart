// Cart and Order DTOs for API layer
import 'package:json_annotation/json_annotation.dart';
import 'base_response_dto.dart';

part 'cart_dto.g.dart';

@JsonSerializable()
class OrderDto {
  final String id;
  final String description;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'is_paid')
  final bool isPaid;
  final int total;
  final String type;
  final String? status;
  @JsonKey(name: 'owner_description')
  final String? ownerDescription;
  final List<OrderItemDto> items;

  OrderDto({
    required this.id,
    required this.description,
    required this.createdAt,
    required this.isPaid,
    required this.total,
    required this.type,
    this.status,
    this.ownerDescription,
    required this.items,
  });

  factory OrderDto.fromJson(Map<String, dynamic> json) => _$OrderDtoFromJson(json);
  Map<String, dynamic> toJson() => _$OrderDtoToJson(this);
}

@JsonSerializable()
class OrderItemDto {
  @JsonKey(name: 'product_name')
  final String productName;
  final int quantity;

  OrderItemDto({
    required this.productName,
    required this.quantity,
  });

  factory OrderItemDto.fromJson(Map<String, dynamic> json) => _$OrderItemDtoFromJson(json);
  Map<String, dynamic> toJson() => _$OrderItemDtoToJson(this);
}

@JsonSerializable()
class OrderCreateDto {
  final String description;
  final String type; // "cash" or "online"
  final List<OrderCreateItemDto> items;

  OrderCreateDto({
    required this.description,
    required this.type,
    required this.items,
  });

  factory OrderCreateDto.fromJson(Map<String, dynamic> json) => _$OrderCreateDtoFromJson(json);
  Map<String, dynamic> toJson() => _$OrderCreateDtoToJson(this);
}

@JsonSerializable()
class OrderCreateItemDto {
  @JsonKey(name: 'product_id')
  final String productId;
  final int quantity;

  OrderCreateItemDto({
    required this.productId,
    required this.quantity,
  });

  factory OrderCreateItemDto.fromJson(Map<String, dynamic> json) => _$OrderCreateItemDtoFromJson(json);
  Map<String, dynamic> toJson() => _$OrderCreateItemDtoToJson(this);
}

@JsonSerializable()
class CartItemDto {
  final String? product;
  @JsonKey(name: 'product_name')
  final String? productName;
  final String? affiliate;
  @JsonKey(name: 'affiliate_name')
  final String? affiliateName;
  final int quantity;

  CartItemDto({
    this.product,
    this.productName,
    this.affiliate,
    this.affiliateName,
    required this.quantity,
  });

  factory CartItemDto.fromJson(Map<String, dynamic> json) => _$CartItemDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CartItemDtoToJson(this);
}

@JsonSerializable()
class CartUpdateItemDto {
  final int quantity;

  CartUpdateItemDto({
    required this.quantity,
  });

  factory CartUpdateItemDto.fromJson(Map<String, dynamic> json) => _$CartUpdateItemDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CartUpdateItemDtoToJson(this);
}

@JsonSerializable()
class OrderVerifyDto {
  final String id;
  final bool verified;
  final String description;

  OrderVerifyDto({
    required this.id,
    required this.verified,
    required this.description,
  });

  factory OrderVerifyDto.fromJson(Map<String, dynamic> json) => _$OrderVerifyDtoFromJson(json);
  Map<String, dynamic> toJson() => _$OrderVerifyDtoToJson(this);
}

// Response DTOs
typedef OrderResponseDto = BaseResponseDto<OrderDto>;
typedef OrderListResponseDto = BaseResponseDto<List<OrderDto>>;
typedef CartItemResponseDto = BaseResponseDto<CartItemDto>;
