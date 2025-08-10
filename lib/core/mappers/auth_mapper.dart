import '../models/dto/auth_dto.dart';
import '../../features/auth/domain/entities/user.dart';

/// Mapper for converting DTOs to domain entities
class AuthMapper {
  AuthMapper._();

  /// Convert UserDto to User entity
  static User userFromDto(UserDto dto) {
    return User(
      id: dto.id,
      mobileNumber: dto.mobileNumber,
      firstName: dto.firstName,
      lastName: dto.lastName,
      email: dto.email,
      isOwner: dto.isOwner,
      dateJoined: dto.dateJoined,
    );
  }

  /// Convert User entity to UserDto
  static UserDto userToDto(User entity) {
    return UserDto(
      id: entity.id,
      mobileNumber: entity.mobileNumber,
      firstName: entity.firstName,
      lastName: entity.lastName,
      email: entity.email,
      isOwner: entity.isOwner,
      dateJoined: entity.dateJoined,
    );
  }

  /// Create PIN request from mobile number
  static PinCreateRequestDto createPinRequest(String mobileNumber) {
    return PinCreateRequestDto(mobileNumber: mobileNumber);
  }

  /// Create PIN verification request
  static PinVerifyRequestDto createPinVerifyRequest({
    required String mobileNumber,
    required String pin,
  }) {
    return PinVerifyRequestDto(
      mobileNumber: mobileNumber,
      pin: pin,
    );
  }
}
