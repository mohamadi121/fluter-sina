import '../../core/models/dto/auth_dto.dart';
import '../../core/models/dto/base_response_dto.dart';
import '../../core/network/app_error.dart';
import '../auth_api_client.dart';

/// Service for handling auth API responses and mapping to domain
class AuthApiService {
  final AuthApiClient _authApiClient;

  AuthApiService(this._authApiClient);

  /// Create PIN with proper error handling
  Future<void> createPin(String mobileNumber) async {
    try {
      final response = await _authApiClient.createPin(mobileNumber);
      
      if (!response.success) {
        throw _mapErrorFromResponse(response);
      }
    } catch (e) {
      if (e is AppError) rethrow;
      throw UnknownError(
        message: 'خطای غیرمنتظره در ارسال کد',
        originalError: e,
      );
    }
  }

  /// Verify PIN and return token
  Future<String> verifyPin(String mobileNumber, String pin) async {
    try {
      final response = await _authApiClient.verifyPin(mobileNumber, pin);
      
      if (!response.success || response.data == null) {
        throw _mapErrorFromResponse(response);
      }
      
      return response.data!.token;
    } catch (e) {
      if (e is AppError) rethrow;
      throw UnknownError(
        message: 'خطای غیرمنتظره در تأیید کد',
        originalError: e,
      );
    }
  }

  /// Map API error response to AppError
  AppError _mapErrorFromResponse(BaseResponseDto response) {
    switch (response.code) {
      case 401:
        return AuthError.unauthorized();
      case 404:
        return const BusinessError(
          message: 'اطلاعات مورد نظر یافت نشد',
          code: '404',
        );
      case 500:
        return const NetworkError(
          message: 'خطا در سرور، لطفاً بعداً تلاش کنید',
          code: '500',
        );
      default:
        return BusinessError(
          message: response.error?.toString() ?? 'خطای ناشناخته',
          code: response.code.toString(),
        );
    }
  }
}
