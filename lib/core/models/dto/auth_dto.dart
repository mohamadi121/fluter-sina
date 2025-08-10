import 'package:json_annotation/json_annotation.dart';

part 'auth_dto.g.dart';

/// PIN creation request DTO
@JsonSerializable()
class PinCreateRequestDto {
  @JsonKey(name: 'mobile_number')
  final String mobileNumber;

  const PinCreateRequestDto({
    required this.mobileNumber,
  });

  factory PinCreateRequestDto.fromJson(Map<String, dynamic> json) =>
      _$PinCreateRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PinCreateRequestDtoToJson(this);
}

/// PIN verification request DTO
@JsonSerializable()
class PinVerifyRequestDto {
  @JsonKey(name: 'mobile_number')
  final String mobileNumber;
  final String pin;

  const PinVerifyRequestDto({
    required this.mobileNumber,
    required this.pin,
  });

  factory PinVerifyRequestDto.fromJson(Map<String, dynamic> json) =>
      _$PinVerifyRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PinVerifyRequestDtoToJson(this);
}

/// Token response DTO (for pin verify)
@JsonSerializable()
class TokenResponseDto {
  final String token;

  const TokenResponseDto({
    required this.token,
  });

  factory TokenResponseDto.fromJson(Map<String, dynamic> json) =>
      _$TokenResponseDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TokenResponseDtoToJson(this);
}
