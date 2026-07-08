import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/helper/secure_storage.dart';
import 'package:asood/core/logging/app_logger.dart';

/// HTTP client for the Asoud backend.
///
/// The backend uses DRF TokenAuthentication: `Authorization: Token <key>`.
/// There is no JWT and no refresh endpoint — a 401 means the token is gone
/// or revoked, so the stored token is wiped and the error propagates for the
/// auth layer to route the user back to login.
class DioClient {
  final String appBaseUrl;
  final int timeoutInSeconds = 30;
  late Dio dio;

  DioClient({required this.appBaseUrl}) {
    dio = Dio(
      BaseOptions(
        baseUrl: appBaseUrl,
        connectTimeout: Duration(seconds: timeoutInSeconds),
        receiveTimeout: Duration(seconds: timeoutInSeconds),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.readSecureStorage(Keys.token);
          if (token != null && token != 'ND') {
            options.headers['Authorization'] = 'Token $token';
          }
          options.extra['startTime'] = DateTime.now();
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logResponse(response.requestOptions, response.statusCode);
          return handler.next(response);
        },
        onError: (error, handler) async {
          _logResponse(
            error.requestOptions,
            error.response?.statusCode,
            error: error,
          );
          if (error.response?.statusCode == 401) {
            await SecureStorage.deleteSecureStorage(Keys.token);
          }
          return handler.next(error);
        },
      ),
    );
  }

  void _logResponse(
    RequestOptions request,
    int? statusCode, {
    DioException? error,
  }) {
    final start = request.extra['startTime'] as DateTime?;
    final elapsed =
        start == null
            ? ''
            : ' ${DateTime.now().difference(start).inMilliseconds}ms';
    final line =
        '${request.method} ${request.path} -> ${statusCode ?? 'no response'}$elapsed';

    if (error == null) {
      AppLogger.info('http', line);
    } else {
      AppLogger.warning('http', line, error.error ?? error.message);
    }
    if (kDebugMode && error?.response?.data != null) {
      AppLogger.debug('http', 'body: ${error!.response!.data}');
    }
  }

  Future<Response> getData(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) {
    return dio.get(
      uri,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    );
  }

  Future<Response> postData(
    String uri,
    dynamic data, {
    Map<String, dynamic>? headers,
  }) {
    return dio.post(uri, data: data, options: Options(headers: headers));
  }

  Future<Response> postMultipartData(
    String uri,
    Map<String, dynamic> data,
    List<MultipartBody> multipartBody, {
    Map<String, dynamic>? headers,
  }) async {
    final formData = await _buildFormData(data, multipartBody);
    return dio.post(uri, data: formData, options: Options(headers: headers));
  }

  Future<Response> patchMultipartData(
    String uri,
    Map<String, String> data,
    List<MultipartBody> multipartBody, {
    Map<String, dynamic>? headers,
  }) async {
    final formData = await _buildFormData(data, multipartBody);
    return dio.patch(uri, data: formData, options: Options(headers: headers));
  }

  Future<Response> putData(
    String uri,
    dynamic data, {
    Map<String, dynamic>? headers,
  }) {
    return dio.put(uri, data: data, options: Options(headers: headers));
  }

  Future<Response> patchData(
    String uri,
    dynamic data, {
    Map<String, dynamic>? headers,
  }) {
    return dio.patch(uri, data: data, options: Options(headers: headers));
  }

  Future<Response> deleteData(String uri, {Map<String, dynamic>? headers}) {
    return dio.delete(uri, options: Options(headers: headers));
  }

  Future<FormData> _buildFormData(
    Map<String, dynamic> data,
    List<MultipartBody> multipartBody,
  ) async {
    final formData = FormData();
    data.forEach((key, value) {
      formData.fields.add(MapEntry(key, value.toString()));
    });
    for (final multipart in multipartBody) {
      final file = multipart.file;
      if (file == null) {
        continue;
      }
      formData.files.add(
        MapEntry(
          multipart.key,
          await MultipartFile.fromFile(file.path, filename: file.name),
        ),
      );
    }
    return formData;
  }
}

class MultipartBody {
  final String key;
  final XFile? file;
  MultipartBody(this.key, this.file);
}
