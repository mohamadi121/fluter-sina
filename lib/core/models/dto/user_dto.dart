// User Profile DTOs for API layer
import 'package:json_annotation/json_annotation.dart';
import 'base_response_dto.dart';

part 'user_dto.g.dart';

@JsonSerializable()
class UserProfileDto {
  final String? address;
  @JsonKey(name: 'national_code')
  final String? nationalCode;
  @JsonKey(name: 'birth_date')
  final String? birthDate;
  @JsonKey(name: 'iban_number')
  final String? ibanNumber;
  final String? picture;

  UserProfileDto({
    this.address,
    this.nationalCode,
    this.birthDate,
    this.ibanNumber,
    this.picture,
  });

  factory UserProfileDto.fromJson(Map<String, dynamic> json) => _$UserProfileDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileDtoToJson(this);
}

@JsonSerializable()
class UserDto {
  final String id;
  @JsonKey(name: 'mobile_number')
  final String mobileNumber;
  final String? email;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'date_joined')
  final String dateJoined;
  final UserProfileDto? profile;

  UserDto({
    required this.id,
    required this.mobileNumber,
    this.email,
    this.firstName,
    this.lastName,
    required this.isActive,
    required this.dateJoined,
    this.profile,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => _$UserDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}

@JsonSerializable()
class UserProfileUpdateDto {
  final String? address;
  @JsonKey(name: 'national_code')
  final String? nationalCode;
  @JsonKey(name: 'birth_date')
  final String? birthDate;
  @JsonKey(name: 'iban_number')
  final String? ibanNumber;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  final String? email;

  UserProfileUpdateDto({
    this.address,
    this.nationalCode,
    this.birthDate,
    this.ibanNumber,
    this.firstName,
    this.lastName,
    this.email,
  });

  factory UserProfileUpdateDto.fromJson(Map<String, dynamic> json) => _$UserProfileUpdateDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileUpdateDtoToJson(this);
}

@JsonSerializable()
class UserDocumentDto {
  final String id;
  final String file;
  @JsonKey(name: 'created_at')
  final String createdAt;

  UserDocumentDto({
    required this.id,
    required this.file,
    required this.createdAt,
  });

  factory UserDocumentDto.fromJson(Map<String, dynamic> json) => _$UserDocumentDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserDocumentDtoToJson(this);
}

// Response DTOs
typedef UserResponseDto = BaseResponseDto<UserDto>;
typedef UserProfileResponseDto = BaseResponseDto<UserProfileDto>;
typedef UserDocumentListResponseDto = BaseResponseDto<List<UserDocumentDto>>;
