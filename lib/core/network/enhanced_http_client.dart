import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../architecture/result.dart';
import '../helper/secure_storage.dart';
import '../constants/constants.dart';

class EnhancedHttpClient {
  late final Dio _dio;
  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  EnhancedHttpClient({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 30),
    this.receiveTimeout = const Duration(seconds: 30),
  }) {
    _initializeDio();
  }

  void _initializeDio() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(AuthInterceptor());
    
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
        logPrint: (message) => debugPrint('HTTP: $message'),
      ));
    }

    _dio.interceptors.add(RetryInterceptor());
  }

  Future<Result<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? transformer,
  }) async {
    return _executeRequest(
      () => _dio.get(path, queryParameters: queryParameters, options: options),
      transformer,
    );
  }

  Future<Result<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? transformer,
  }) async {
    return _executeRequest(
      () => _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      transformer,
    );
  }

  Future<Result<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? transformer,
  }) async {
    return _executeRequest(
      () => _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      transformer,
    );
  }

  Future<Result<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? transformer,
  }) async {
    return _executeRequest(
      () => _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      transformer,
    );
  }

  Future<Result<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? transformer,
  }) async {
    return _executeRequest(
      () => _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      transformer,
    );
  }

  Future<Result<T>> _executeRequest<T>(
    Future<Response> Function() request,
    T Function(dynamic)? transformer,
  ) async {
    try {
      final response = await request();
      
      if (response.statusCode != null && 
          response.statusCode! >= 200 && 
          response.statusCode! < 300) {
        
        final data = transformer != null 
            ? transformer(response.data)
            : response.data as T;
            
        return Success(data);
      } else {
        return Failure(NetworkError(
          'HTTP ${response.statusCode}: ${response.statusMessage}',
          statusCode: response.statusCode,
          data: response.data,
        ));
      }
    } on DioException catch (e) {
      return Failure(_handleDioException(e));
    } catch (e, stackTrace) {
      return Failure(UnknownError(
        'Unexpected error: ${e.toString()}',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  ResultError _handleDioException(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutError('Request timeout');
        
      case DioExceptionType.badResponse:
        final statusCode = exception.response?.statusCode;
        final message = exception.response?.statusMessage ?? 'Bad response';
        return NetworkError(
          message,
          statusCode: statusCode,
          data: exception.response?.data,
        );
        
      case DioExceptionType.cancel:
        return const NetworkError('Request cancelled');
        
      case DioExceptionType.connectionError:
        return const NetworkError('Connection failed');
        
      case DioExceptionType.badCertificate:
        return const NetworkError('SSL certificate error');
        
      case DioExceptionType.unknown:
        return NetworkError(
          exception.message ?? 'Unknown network error',
          data: exception.response?.data,
        );
    }
  }

  void close() {
    _dio.close();
  }
}

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.readSecureStorage(Keys.token);
    
    if (token != null && token != "ND") {
      options.headers['Authorization'] = 'Token $token';
    }
    
    handler.next(options);
  }
}

class RetryInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final shouldRetry = _shouldRetry(err);
    final retryCount = err.requestOptions.extra['retryCount'] ?? 0;
    
    if (shouldRetry && retryCount < EnhancedHttpClient.maxRetries) {
      err.requestOptions.extra['retryCount'] = retryCount + 1;
      
      await Future.delayed(
        EnhancedHttpClient.retryDelay * (retryCount + 1),
      );
      
      try {
        final dio = Dio();
        final response = await dio.fetch(err.requestOptions);
        handler.resolve(response);
      } catch (e) {
        handler.next(err);
      }
    } else {
      handler.next(err);
    }
  }

  bool _shouldRetry(DioException error) {
    return error.type == DioExceptionType.connectionTimeout ||
           error.type == DioExceptionType.receiveTimeout ||
           error.type == DioExceptionType.connectionError ||
           (error.response?.statusCode != null &&
            error.response!.statusCode! >= 500);
  }
}