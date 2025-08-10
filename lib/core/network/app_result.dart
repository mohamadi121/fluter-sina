import 'package:dio/dio.dart';
import 'app_error.dart';

/// Unified result wrapper for API/domain layers
sealed class AppResult<T> {
  const AppResult();
  R when<R>({required R Function(T data) success, required R Function(AppError error) failure}) {
    final self = this;
    if (self is Success<T>) return success(self.data);
    return failure((self as Failure<T>).error);
  }
  
  R fold<R>({required R Function(T data) success, required R Function(AppError error) failure}) {
    final self = this;
    if (self is Success<T>) return success(self.data);
    return failure((self as Failure<T>).error);
  }
  
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
  T? get dataOrNull => this is Success<T> ? (this as Success<T>).data : null;
  AppError? get errorOrNull => this is Failure<T> ? (this as Failure<T>).error : null;
}

class Success<T> extends AppResult<T> {
  final T data;
  final int? statusCode;
  const Success(this.data, {this.statusCode});
}

class Failure<T> extends AppResult<T> {
  final AppError error;
  final int? statusCode;
  const Failure(this.error, {this.statusCode});
}

/// Helper utilities to transform a Dio [Response] that follows the Asoud envelope
/// { success: bool, code: int, data: ..., message: ..., error: {...} }
class ResultMapper {
  static AppResult<R> fromEnvelope<R>(
    Response response, {
    required R Function(dynamic json) dataParser,
  }) {
    final int? status = response.statusCode;
    final body = response.data;
    if (body is Map<String, dynamic>) {
      final success = body['success'] == true;
      if (success) {
        try {
          final parsed = dataParser(body['data']);
          return Success<R>(parsed, statusCode: status);
        } catch (e) {
          return Failure<R>(
            UnknownError(message: 'خطا در پردازش پاسخ سرور', originalError: e),
            statusCode: status,
          );
        }
      } else {
        // Try structured error
        final err = ErrorHandler.fromEnvelope(body) ?? UnknownError(
          message: body['message']?.toString() ?? 'خطای ناشناخته',
        );
        return Failure<R>(err, statusCode: status);
      }
    }
    // Fallback if body is not envelope map
    try {
      final parsed = dataParser(body);
      return Success<R>(parsed, statusCode: status);
    } catch (e) {
      return Failure<R>(
        UnknownError(message: 'پاسخ غیرقابل پردازش دریافت شد', originalError: e),
        statusCode: status,
      );
    }
  }
}
