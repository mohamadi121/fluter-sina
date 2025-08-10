import 'package:json_annotation/json_annotation.dart';

part 'base_response_dto.g.dart';

/// Base response envelope for all API responses
@JsonSerializable(genericArgumentFactories: true)
class BaseResponseDto<T> {
  final bool success;
  final int code;
  final T? data;
  final String? message;
  final dynamic error;

  const BaseResponseDto({
    required this.success,
    required this.code,
    this.data,
    this.message,
    this.error,
  });

  factory BaseResponseDto.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$BaseResponseDtoFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object Function(T value) toJsonT) =>
      _$BaseResponseDtoToJson(this, toJsonT);
}

/// Error details DTO
@JsonSerializable()
class ErrorDetailsDto {
  final String code;
  final String detail;

  const ErrorDetailsDto({
    required this.code,
    required this.detail,
  });

  factory ErrorDetailsDto.fromJson(Map<String, dynamic> json) =>
      _$ErrorDetailsDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ErrorDetailsDtoToJson(this);
}

/// Empty data DTO for responses without data
@JsonSerializable()
class EmptyDto {
  const EmptyDto();

  factory EmptyDto.fromJson(Map<String, dynamic> json) =>
      _$EmptyDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EmptyDtoToJson(this);
}
