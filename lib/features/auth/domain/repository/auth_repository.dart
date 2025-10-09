import 'package:asood/core/architecture/result.dart';

/// Repository interface for authentication operations
/// 
/// This repository defines the contract for authentication-related
/// data operations. The implementation should handle the actual
/// API calls and data persistence.
abstract class AuthRepository {
  /// Send OTP code to the given phone number
  /// 
  /// Returns [Success] if OTP was sent successfully,
  /// [Failure] with appropriate error if failed.
  Future<Result<void>> sendCode(String phoneNumber);

  /// Verify OTP code for the given phone number
  /// 
  /// Returns [Success] with user data if verification is successful,
  /// [Failure] with appropriate error if failed.
  Future<Result<Map<String, dynamic>>> verifyCode(String phoneNumber, String code);

  /// Logout the current user
  /// 
  /// Returns [Success] if logout was successful,
  /// [Failure] with appropriate error if failed.
  Future<Result<void>> logout();
}
