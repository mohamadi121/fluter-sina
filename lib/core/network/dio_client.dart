import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../config/env_config.dart';
import '../helper/secure_storage.dart';
import '../constants/constants.dart';
import 'app_error.dart';

class DioClient {
  final String appBaseUrl;
  late Dio dio;

  DioClient({required this.appBaseUrl}) {
    _initializeDio();
    _addInterceptors();
  }

  void _initializeDio() {
    dio = Dio(
      BaseOptions(
        baseUrl: appBaseUrl,
        connectTimeout: Duration(seconds: EnvConfig.apiTimeout),
        receiveTimeout: Duration(seconds: EnvConfig.apiTimeout),
        sendTimeout: Duration(seconds: EnvConfig.apiTimeout),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
      ),
    );
  }

  void _addInterceptors() {
    // Auth interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          await _addAuthHeader(options);
          if (EnvConfig.enableLogs && kDebugMode) {
            debugPrint('🚀 ${options.method} ${options.path}');
            if (options.data != null) {
              debugPrint('📦 Body: ${options.data}');
            }
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (EnvConfig.enableLogs && kDebugMode) {
            debugPrint('✅ ${response.statusCode} ${response.requestOptions.path}');
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (EnvConfig.enableLogs && kDebugMode) {
            debugPrint('❌ ${error.response?.statusCode} ${error.requestOptions.path}');
            debugPrint('Error: ${error.message}');
          }
          handler.next(error);
        },
      ),
    );

    // Retry interceptor for network failures
    dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (_shouldRetry(error)) {
            try {
              final response = await dio.fetch(error.requestOptions);
              handler.resolve(response);
            } catch (e) {
              handler.next(error);
            }
          } else {
            handler.next(error);
          }
        },
      ),
    );

    // Add detailed logging in debug mode
    if (EnvConfig.enableLogs && kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          logPrint: (log) => debugPrint(log.toString()),
        ),
      );
    }
  }

  Future<void> _addAuthHeader(RequestOptions options) async {
    final token = await SecureStorage.readSecureStorage(Keys.token);
    if (token != null && token != "ND" && token.isNotEmpty) {
      options.headers['Authorization'] = 'Token $token';
    }
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError;
  }

  /// GET request with proper error handling
  Future<Response> getData(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await dio.get(
        uri,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    }
  }

  /// POST request with proper error handling
  Future<Response> postData(
    String uri,
    dynamic data, {
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await dio.post(
        uri,
        data: data,
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    }
  }

  /// PUT request with proper error handling
  Future<Response> putData(
    String uri,
    dynamic data, {
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await dio.put(
        uri,
        data: data,
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    }
  }

  /// PATCH request with proper error handling
  Future<Response> patchData(
    String uri,
    dynamic data, {
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await dio.patch(
        uri,
        data: data,
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    }
  }

  /// DELETE request with proper error handling
  Future<Response> deleteData(
    String uri, {
    Map<String, dynamic>? headers,
  }) async {
    try {
      final response = await dio.delete(
        uri,
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    }
  }

  /// Multipart POST request with proper error handling
  Future<Response> postMultipartData(
    String uri,
    Map<String, dynamic> data,
    List<MultipartBody> multipartBody, {
    Map<String, dynamic>? headers,
  }) async {
    try {
      final formData = FormData();
      
      // Add text fields
      data.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });
      
      // Add files
      for (final multipart in multipartBody) {
        if (multipart.file != null) {
          final fileName = multipart.file!.name;
          formData.files.add(
            MapEntry(
              multipart.key,
              await MultipartFile.fromFile(
                multipart.file!.path,
                filename: fileName,
              ),
            ),
          );
        }
      }

      final response = await dio.post(
        uri,
        data: formData,
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    }
  }

  /// Multipart PATCH request with proper error handling
  Future<Response> patchMultipartData(
    String uri,
    Map<String, String> data,
    List<MultipartBody> multipartBody, {
    Map<String, dynamic>? headers,
  }) async {
    try {
      final formData = FormData();
      
      // Add text fields
      data.forEach((key, value) {
        formData.fields.add(MapEntry(key, value));
      });
      
      // Add files
      for (final multipart in multipartBody) {
        if (multipart.file != null) {
          final fileName = multipart.file!.name;
          formData.files.add(
            MapEntry(
              multipart.key,
              await MultipartFile.fromFile(
                multipart.file!.path,
                filename: fileName,
              ),
            ),
          );
        }
      }

      final response = await dio.patch(
        uri,
        data: formData,
        options: Options(headers: headers),
      );
      return response;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    }
  }
}

/// Model for handling multipart file uploads
class MultipartBody {
  final String key;
  final XFile? file;
  
  MultipartBody(this.key, this.file);
}
