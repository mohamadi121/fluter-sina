import 'package:dio/dio.dart';

/// Unified error handling for the application
sealed class AppError {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppError({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() => message;

  /// Creates an AppError from any exception
  static AppError fromException(dynamic exception) {
    if (exception is DioException) {
      return ErrorHandler.handleDioError(exception);
    }
    
    return UnknownError(
      message: exception?.toString() ?? 'خطای غیرمنتظره',
      originalError: exception,
    );
  }
}

/// Network related errors
class NetworkError extends AppError {
  const NetworkError({
    required super.message,
    super.code,
    super.originalError,
  });

  factory NetworkError.noConnection() => const NetworkError(
        message: 'اتصال به اینترنت برقرار نیست',
        code: 'NO_CONNECTION',
      );

  factory NetworkError.timeout() => const NetworkError(
        message: 'زمان اتصال به پایان رسید',
        code: 'TIMEOUT',
      );

  factory NetworkError.serverError(int statusCode) => NetworkError(
        message: _getServerErrorMessage(statusCode),
        code: statusCode.toString(),
      );
}

/// Authentication related errors
class AuthError extends AppError {
  const AuthError({
    required super.message,
    super.code,
    super.originalError,
  });

  factory AuthError.unauthorized() => const AuthError(
        message: 'لطفاً مجدداً وارد شوید',
        code: 'UNAUTHORIZED',
      );

  factory AuthError.forbidden() => const AuthError(
        message: 'دسترسی غیرمجاز',
        code: 'FORBIDDEN',
      );

  factory AuthError.tokenExpired() => const AuthError(
        message: 'نشست شما منقضی شده است',
        code: 'TOKEN_EXPIRED',
      );
}

/// Validation related errors
class ValidationError extends AppError {
  final Map<String, List<String>>? fieldErrors;

  const ValidationError({
    required super.message,
    super.code,
    this.fieldErrors,
    super.originalError,
  });

  factory ValidationError.fromResponse(Map<String, dynamic> response) {
    return ValidationError(
      message: 'اطلاعات وارد شده صحیح نیست',
      code: 'VALIDATION_ERROR',
      fieldErrors: _parseFieldErrors(response),
    );
  }

  static Map<String, List<String>>? _parseFieldErrors(
    Map<String, dynamic> response,
  ) {
    if (response.isEmpty) return null;

    final Map<String, List<String>> errors = {};
    response.forEach((key, value) {
      if (value is List) {
        errors[key] = value.map((e) => e.toString()).toList();
      } else if (value is String) {
        errors[key] = [value];
      }
    });
    return errors.isNotEmpty ? errors : null;
  }
}

/// Business logic related errors
class BusinessError extends AppError {
  const BusinessError({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Unknown/unexpected errors
class UnknownError extends AppError {
  const UnknownError({
    required super.message,
    super.code,
    super.originalError,
  });
}

/// Converts DioException to AppError
class ErrorHandler {
  static AppError handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkError.timeout();
      case DioExceptionType.connectionError:
        return NetworkError.noConnection();
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        return _handleStatusCode(statusCode, error.response?.data);
      case DioExceptionType.cancel:
        return const UnknownError(
          message: 'درخواست لغو شد',
          code: 'REQUEST_CANCELLED',
        );
      default:
        return UnknownError(
          message: 'خطای غیرمنتظره رخ داد',
          originalError: error,
        );
    }
  }

  /// Parse standard envelope error { success:false, code:int, error:{ code, detail } }
  static AppError? fromEnvelope(Map<String, dynamic> json) {
    try {
      if (json['success'] == false) {
        final err = json['error'];
        if (err is Map<String, dynamic>) {
          final code = err['code']?.toString();
          final detail = err['detail']?.toString() ?? 'خطا';
          // Map common error codes
          switch (code) {
            case 'UNAUTHORIZED':
            case '401':
              return AuthError.unauthorized();
            case 'FORBIDDEN':
            case '403':
              return AuthError.forbidden();
            case 'VALIDATION_ERROR':
              return ValidationError.fromResponse(err);
            default:
              return BusinessError(message: detail, code: code);
          }
        }
        // fallback message
        final msg = json['message']?.toString() ?? 'خطای ناشناخته';
        return BusinessError(message: msg, code: json['code']?.toString());
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static AppError _handleStatusCode(int statusCode, dynamic responseData) {
    switch (statusCode) {
      case 400:
        if (responseData is Map<String, dynamic>) {
          return ValidationError.fromResponse(responseData);
        }
        return const ValidationError(
          message: 'اطلاعات وارد شده صحیح نیست',
          code: '400',
        );
      case 401:
        return AuthError.unauthorized();
      case 403:
        return AuthError.forbidden();
      case 404:
        return const BusinessError(
          message: 'اطلاعات مورد نظر یافت نشد',
          code: '404',
        );
      case 422:
        if (responseData is Map<String, dynamic>) {
          return ValidationError.fromResponse(responseData);
        }
        return const ValidationError(
          message: 'اطلاعات وارد شده قابل پردازش نیست',
          code: '422',
        );
      case 500:
      case 502:
      case 503:
        return const NetworkError(
          message: 'خطا در سرور، لطفاً بعداً تلاش کنید',
          code: 'SERVER_ERROR',
        );
      default:
        return NetworkError.serverError(statusCode);
    }
  }
}

String _getServerErrorMessage(int statusCode) {
  switch (statusCode) {
    case 500:
      return 'خطای داخلی سرور';
    case 502:
      return 'سرور در دسترس نیست';
    case 503:
      return 'سرویس موقتاً در دسترس نیست';
    default:
      return 'خطا در ارتباط با سرور (کد: $statusCode)';
  }
}
