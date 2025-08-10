import 'package:json_annotation/json_annotation.dart';

part 'category_dto.g.dart';

/// Category group DTO
@JsonSerializable()
class CategoryGroupDto {
  final String id;
  final String title;

  const CategoryGroupDto({
    required this.id,
    required this.title,
  });

  factory CategoryGroupDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryGroupDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryGroupDtoToJson(this);
}

/// Category DTO
@JsonSerializable()
class CategoryDto {
  final String id;
  final String title;
  final String? description;
  @JsonKey(name: 'group_id')
  final String? groupId;

  const CategoryDto({
    required this.id,
    required this.title,
    this.description,
    this.groupId,
  });

  factory CategoryDto.fromJson(Map<String, dynamic> json) =>
      _$CategoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CategoryDtoToJson(this);
}

/// SubCategory DTO
@JsonSerializable()
class SubCategoryDto {
  final String id;
  final String title;
  @JsonKey(name: 'category_id')
  final String? categoryId;

  const SubCategoryDto({
    required this.id,
    required this.title,
    this.categoryId,
  });

  factory SubCategoryDto.fromJson(Map<String, dynamic> json) =>
      _$SubCategoryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SubCategoryDtoToJson(this);
}
