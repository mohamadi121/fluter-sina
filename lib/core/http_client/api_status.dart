import 'package:dio/dio.dart';

import 'package:asood/core/logging/app_logger.dart';

import 'error_response.dart';

class Success {
  int? code;
  Object? response;
  String? message;

  Success({this.code, this.response, this.message});
}

enum FailureKind {
  network,
  unauthorized,
  forbidden,
  notFound,
  validation,
  server,
  parsing,
  unknown,
}

class Failure {
  final int? code;
  final Object? errorResponse;
  final FailureKind kind;

  Failure({this.code, this.errorResponse, this.kind = FailureKind.unknown});

  bool get isAuthError => kind == FailureKind.unauthorized;

  String get message => errorResponse?.toString() ?? 'خطای نامشخص';
}

/// Maps a 2xx backend body to Success/Failure.
///
/// Most endpoints use the ApiResponse envelope `{success, code, data,
/// message}` / `{success, code, error}`. Some (comments, cart viewset)
/// return bare DRF serializer data — a Map without a `success` key or a
/// List — which is a success at this point because dio already threw for
/// non-2xx statuses.
dynamic apiStatus(Response response) {
  try {
    final res = response.data;

    if (res is List || (res is Map && !res.containsKey('success'))) {
      return Success(code: response.statusCode, response: res);
    }

    if (res['success'] == true) {
      return Success(
        code: res['code'],
        response: res['data'],
        message: res['message'],
      );
    }
    return Failure(
      code: res['code'],
      errorResponse: _envelopeDetail(res) ?? 'خطای نامشخص',
      kind: FailureKind.validation,
    );
  } catch (e, st) {
    AppLogger.error(
      'api',
      'unexpected response shape from ${response.requestOptions.path}',
      e,
      st,
    );
    return Failure(
      code: response.statusCode ?? 500,
      errorResponse: 'خطای پردازش پاسخ سرور',
      kind: FailureKind.parsing,
    );
  }
}

/// Maps a thrown error (usually DioException on non-2xx or network trouble)
/// to a typed Failure, preserving the backend's error detail when present.
Failure apiFailure(Object error) {
  if (error is! DioException) {
    AppLogger.error('api', 'non-dio error escaped a data source', error);
    return Failure(errorResponse: 'خطای غیرمنتظره', kind: FailureKind.unknown);
  }

  final response = error.response;
  if (response == null) {
    return Failure(
      code: null,
      errorResponse: 'عدم برقراری ارتباط با سرور',
      kind: FailureKind.network,
    );
  }

  final status = response.statusCode ?? 500;
  final detail = _envelopeDetail(response.data) ?? handleHttpError(status);

  return Failure(
    code: status,
    errorResponse: detail,
    kind: _kindForStatus(status),
  );
}

/// Extracts a human-readable error detail from any of the backend's error
/// shapes:
/// - hand-built ApiResponse: `error: {code, detail}` or `error: "<string>"`
/// - DRF exception handler (apps/core/exception_handler.py):
///   `{error: true, message, details, original_error}`
/// - plain DRF: `{detail: ...}`
String? _envelopeDetail(dynamic data) {
  if (data is! Map) {
    return null;
  }
  final error = data['error'];
  if (error is Map && error['detail'] != null) {
    return error['detail'].toString();
  }
  if (error is String && error.isNotEmpty) {
    return error;
  }
  if (error == true) {
    final detail = data['message'] ?? data['details'];
    if (detail != null) {
      return detail.toString();
    }
  }
  if (data['detail'] != null) {
    return data['detail'].toString();
  }
  return null;
}

FailureKind _kindForStatus(int status) {
  if (status == 401) return FailureKind.unauthorized;
  if (status == 403) return FailureKind.forbidden;
  if (status == 404) return FailureKind.notFound;
  if (status >= 400 && status < 500) return FailureKind.validation;
  return FailureKind.server;
}

enum CWSStatus { initial, loading, success, failure }
