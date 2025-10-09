import 'package:asood/core/architecture/result.dart';
import 'package:asood/core/domain/usecase.dart';
import 'package:asood/features/auth/domain/entities/user.dart';
import 'package:asood/features/auth/domain/repository/auth_repository.dart';

/// Use case for sending OTP to user's phone number
/// 
/// This use case encapsulates the business logic for OTP sending:
/// - Phone number validation
/// - Iranian phone number format checking
/// - Rate limiting (business rule)
/// - Repository delegation
class SendOtpUseCase implements UseCase<void, SendOtpParams> {
  final AuthRepository _repository;

  const SendOtpUseCase(this._repository);

  @override
  Future<Result<void>> call(SendOtpParams params) async {
    // Business rule: Validate phone number format
    if (!_isValidIranianPhoneNumber(params.phoneNumber)) {
      return const Failure(ValidationError(
        'شماره تلفن باید با 09 شروع شده و 11 رقم باشد',
        field: 'phoneNumber',
      ));
    }

    // Business rule: Check for empty or whitespace-only numbers
    if (params.phoneNumber.trim().isEmpty) {
      return const Failure(ValidationError(
        'شماره تلفن نمی‌تواند خالی باشد',
        field: 'phoneNumber',
      ));
    }

    // Business rule: Normalize phone number (remove any extra characters)
    final normalizedPhone = _normalizePhoneNumber(params.phoneNumber);

    try {
      // Delegate to repository for actual sending
      final result = await _repository.sendCode(normalizedPhone);
      
      if (result is Success) {
        return const Success(null);
      } else {
        // Convert repository errors to domain errors
        return _mapRepositoryError(result as Failure);
      }
    } catch (e) {
      // Handle unexpected errors
      return Failure(NetworkError(
        'خطا در ارسال کد تایید. لطفا دوباره تلاش کنید.',
      ));
    }
  }

  /// Validate Iranian mobile phone number format
  bool _isValidIranianPhoneNumber(String phoneNumber) {
    // Iranian mobile numbers: 09XXXXXXXXX (11 digits)
    final pattern = RegExp(r'^09\d{9}$');
    return pattern.hasMatch(phoneNumber.replaceAll(RegExp(r'\s+'), ''));
  }

  /// Normalize phone number by removing spaces and dashes
  String _normalizePhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  /// Map repository errors to appropriate domain errors
  Failure _mapRepositoryError(Failure repositoryError) {
    final error = repositoryError.error;
    
    if (error is NetworkError) {
      return Failure(NetworkError(
        'خطا در برقراری ارتباط. اتصال اینترنت خود را بررسی کنید.',
      ));
    }
    
    if (error is ValidationError) {
      return Failure(ValidationError(
        'شماره تلفن نامعتبر است',
        field: 'phoneNumber',
      ));
    }
    
    // Default error mapping
    return Failure(UnknownError(
      'خطای غیرمنتظره رخ داده. لطفا دوباره تلاش کنید.',
    ));
  }
}

/// Parameters for SendOtpUseCase
class SendOtpParams extends UseCaseParams {
  final String phoneNumber;

  const SendOtpParams({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];

  @override
  String toString() => 'SendOtpParams(phoneNumber: $phoneNumber)';
}

/// Use case for verifying OTP code
class VerifyOtpUseCase implements UseCase<User, VerifyOtpParams> {
  final AuthRepository _repository;

  const VerifyOtpUseCase(this._repository);

  @override
  Future<Result<User>> call(VerifyOtpParams params) async {
    // Business rule: Validate OTP code format
    if (!_isValidOtpCode(params.code)) {
      return const Failure(ValidationError(
        'کد تایید باید 4 رقم باشد',
        field: 'code',
      ));
    }

    // Business rule: Validate phone number
    if (!_isValidIranianPhoneNumber(params.phoneNumber)) {
      return const Failure(ValidationError(
        'شماره تلفن نامعتبر است',
        field: 'phoneNumber',
      ));
    }

    try {
      final result = await _repository.verifyCode(
        _normalizePhoneNumber(params.phoneNumber),
        params.code,
      );

      return result.fold(
        onSuccess: (data) {
          // Convert data model to domain entity
          if (data is Map<String, dynamic>) {
            final user = _mapToUserEntity(data);
            return Success(user);
          }
          return const Failure(UnknownError('Invalid response format'));
        },
        onFailure: (error) => _mapRepositoryError(error),
      );
    } catch (e) {
      return Failure(NetworkError(
        'خطا در تایید کد. لطفا دوباره تلاش کنید.',
      ));
    }
  }

  /// Validate OTP code format (4 digits)
  bool _isValidOtpCode(String code) {
    final pattern = RegExp(r'^\d{4}$');
    return pattern.hasMatch(code);
  }

  /// Validate Iranian mobile phone number format
  bool _isValidIranianPhoneNumber(String phoneNumber) {
    final pattern = RegExp(r'^09\d{9}$');
    return pattern.hasMatch(phoneNumber.replaceAll(RegExp(r'\s+'), ''));
  }

  /// Normalize phone number
  String _normalizePhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }

  /// Map API response to User entity
  User _mapToUserEntity(Map<String, dynamic> data) {
    return User(
      id: data['id']?.toString() ?? '',
      phoneNumber: data['phone_number']?.toString() ?? '',
      isVerified: data['is_verified'] == true,
      firstName: data['first_name']?.toString(),
      lastName: data['last_name']?.toString(),
      email: data['email']?.toString(),
      createdAt: data['created_at'] != null 
        ? DateTime.tryParse(data['created_at'].toString())
        : null,
      lastLoginAt: DateTime.now(), // Set current time as last login
      status: _mapUserStatus(data['status']?.toString()),
    );
  }

  /// Map status string to UserStatus enum
  UserStatus _mapUserStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
        return UserStatus.active;
      case 'suspended':
        return UserStatus.suspended;
      case 'banned':
        return UserStatus.banned;
      case 'pending':
        return UserStatus.pending;
      case 'inactive':
        return UserStatus.inactive;
      default:
        return UserStatus.active; // Default to active
    }
  }

  /// Map repository errors to domain errors
  Failure _mapRepositoryError(ResultError error) {
    if (error is NetworkError) {
      return Failure(NetworkError(
        'خطا در برقراری ارتباط. اتصال اینترنت خود را بررسی کنید.',
      ));
    }
    
    if (error is ValidationError) {
      return Failure(AuthError(
        'کد تایید نامعتبر است',
      ));
    }
    
    return Failure(AuthError(
      'خطا در احراز هویت. لطفا دوباره تلاش کنید.',
    ));
  }
}

/// Parameters for VerifyOtpUseCase
class VerifyOtpParams extends UseCaseParams {
  final String phoneNumber;
  final String code;

  const VerifyOtpParams({
    required this.phoneNumber,
    required this.code,
  });

  @override
  List<Object?> get props => [phoneNumber, code];

  @override
  String toString() => 'VerifyOtpParams(phoneNumber: $phoneNumber, code: $code)';
}

/// Use case for logging out user
class LogoutUseCase implements NoParamsUseCase<void> {
  final AuthRepository _repository;

  const LogoutUseCase(this._repository);

  @override
  Future<Result<void>> call() async {
    try {
      final result = await _repository.logout();
      
      if (result is Success) {
        return const Success(null);
      } else {
        return Failure(AuthError(
          'خطا در خروج از حساب کاربری',
        ));
      }
    } catch (e) {
      return Failure(NetworkError(
        'خطا در برقراری ارتباط',
      ));
    }
  }
}