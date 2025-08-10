// Product DTOs for API layer
import 'package:json_annotation/json_annotation.dart';
import 'base_response_dto.dart';

part 'product_dto.g.dart';

@JsonSerializable()
class ProductDto {
  final String id;
  final String name;
  final String description;
  @JsonKey(name: 'technical_detail')
  final String? technicalDetail;
  final int stock;
  @JsonKey(name: 'main_price')
  final String mainPrice;
  final String? price;
  @JsonKey(name: 'colleague_price')
  final String? colleaguePrice;
  @JsonKey(name: 'marketer_price')
  final String? marketerPrice;
  @JsonKey(name: 'maximum_sell_price')
  final String? maximumSellPrice;
  final String status;
  @JsonKey(name: 'required_product')
  final String? requiredProduct;
  @JsonKey(name: 'gift_product')
  final String? giftProduct;
  @JsonKey(name: 'is_marketer')
  final bool isMarketer;
  @JsonKey(name: 'is_requirement')
  final bool isRequirement;
  final String tag;
  @JsonKey(name: 'tag_position')
  final String tagPosition;
  @JsonKey(name: 'sell_type')
  final String sellType;
  @JsonKey(name: 'ship_cost')
  final String shipCost;
  @JsonKey(name: 'ship_cost_pay_type')
  final String shipCostPayType;
  final String? market;
  final String type;
  @JsonKey(name: 'sub_category')
  final String subCategory;
  final List<String> keywords;
  final List<ProductImageDto> images;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  ProductDto({
    required this.id,
    required this.name,
    required this.description,
    this.technicalDetail,
    required this.stock,
    required this.mainPrice,
    this.price,
    this.colleaguePrice,
    this.marketerPrice,
    this.maximumSellPrice,
    required this.status,
    this.requiredProduct,
    this.giftProduct,
    required this.isMarketer,
    required this.isRequirement,
    required this.tag,
    required this.tagPosition,
    required this.sellType,
    required this.shipCost,
    required this.shipCostPayType,
    this.market,
    required this.type,
    required this.subCategory,
    required this.keywords,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductDto.fromJson(Map<String, dynamic> json) => _$ProductDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ProductDtoToJson(this);
}

@JsonSerializable()
class ProductImageDto {
  final String id;
  final String image;

  ProductImageDto({
    required this.id,
    required this.image,
  });

  factory ProductImageDto.fromJson(Map<String, dynamic> json) => _$ProductImageDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ProductImageDtoToJson(this);
}

@JsonSerializable()
class ProductListItemDto {
  final String id;
  final String name;
  final CategoryDto? category;
  final String price;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  final List<ProductImageDto> images;

  ProductListItemDto({
    required this.id,
    required this.name,
    this.category,
    required this.price,
    required this.updatedAt,
    required this.images,
  });

  factory ProductListItemDto.fromJson(Map<String, dynamic> json) => _$ProductListItemDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ProductListItemDtoToJson(this);
}

@JsonSerializable()
class CategoryDto {
  final String id;
  final String title;

  CategoryDto({
    required this.id,
    required this.title,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) => _$CategoryDtoFromJson(json);
  Map<String, dynamic> toJson() => _$CategoryDtoToJson(this);
}

@JsonSerializable()
class ProductCreateDto {
  final String market;
  final String type;
  final String name;
  final String description;
  @JsonKey(name: 'technical_details')
  final String? technicalDetails;
  @JsonKey(name: 'sub_category')
  final String subCategory;
  final List<String> keywords;
  final int stock;
  final int price;
  @JsonKey(name: 'main_price')
  final int mainPrice;
  @JsonKey(name: 'colleague_price')
  final int? colleaguePrice;
  @JsonKey(name: 'marketer_price')
  final int? marketerPrice;
  @JsonKey(name: 'maximum_sell_price')
  final int? maximumSellPrice;
  final String status;
  @JsonKey(name: 'required_product')
  final String? requiredProduct;
  @JsonKey(name: 'gift_product')
  final String? giftProduct;
  @JsonKey(name: 'is_marketer')
  final bool isMarketer;
  @JsonKey(name: 'is_requirement')
  final bool isRequirement;
  final String tag;
  @JsonKey(name: 'tag_position')
  final String tagPosition;
  @JsonKey(name: 'sell_type')
  final String sellType;
  @JsonKey(name: 'ship_cost')
  final int shipCost;
  @JsonKey(name: 'ship_cost_pay_type')
  final String shipCostPayType;

  ProductCreateDto({
    required this.market,
    required this.type,
    required this.name,
    required this.description,
    this.technicalDetails,
    required this.subCategory,
    required this.keywords,
    required this.stock,
    required this.price,
    required this.mainPrice,
    this.colleaguePrice,
    this.marketerPrice,
    this.maximumSellPrice,
    required this.status,
    this.requiredProduct,
    this.giftProduct,
    required this.isMarketer,
    required this.isRequirement,
    required this.tag,
    required this.tagPosition,
    required this.sellType,
    required this.shipCost,
    required this.shipCostPayType,
  });

  factory ProductCreateDto.fromJson(Map<String, dynamic> json) => _$ProductCreateDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ProductCreateDtoToJson(this);
}

@JsonSerializable()
class ProductThemeDto {
  final String id;
  final String name;
  final int order;
  final List<ProductDto> products;

  ProductThemeDto({
    required this.id,
    required this.name,
    required this.order,
    required this.products,
  });

  factory ProductThemeDto.fromJson(Map<String, dynamic> json) => _$ProductThemeDtoFromJson(json);
  Map<String, dynamic> toJson() => _$ProductThemeDtoToJson(this);
}

// Response DTOs
typedef ProductResponseDto = BaseResponseDto<ProductDto>;
typedef ProductListResponseDto = BaseResponseDto<List<ProductListItemDto>>;
typedef ProductThemeListResponseDto = BaseResponseDto<List<ProductThemeDto>>;
