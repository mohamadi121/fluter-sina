import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/helper/secure_storage.dart';

import 'error_response.dart';

class DioClient {
  final String appBaseUrl;
  final int timeoutInSeconds = 30;
  late Dio dio;

  DioClient({required this.appBaseUrl}) {
    // Initialize Dio with base options
    dio = Dio(
      BaseOptions(
        baseUrl: appBaseUrl,
        connectTimeout: Duration(seconds: timeoutInSeconds),
        receiveTimeout: Duration(seconds: timeoutInSeconds),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      ),
    );

    // Add an interceptor to attach token to requests
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? token = await SecureStorage.readSecureStorage(Keys.token);

          if (token != "ND" && token != null) {
            options.headers['Authorization'] = 'Token $token';
            debugPrint('🚀 Token being sent: $token'); // این خط جدید اضافه شده
          }
          if (kDebugMode) {
            debugPrint(
              '====> API Call: ${options.path}\nHeader: ${options.headers}',
            );
          }
          return handler.next(options);
        },

        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint('====> API Error: ${error.message}');
          }
          return handler.next(error);
        },
      ),
    );
    dio.interceptors.add(
      LogInterceptor(
        request: true, // نمایش اطلاعات درخواست
        requestHeader: true, // نمایش هدرهای درخواست
        requestBody: true, // نمایش بدنه درخواست
        responseHeader: false, // نمایش هدرهای پاسخ
        responseBody: true, // نمایش بدنه پاسخ
        error: true, // نمایش ارورها
        logPrint: (log) => print(log), // تابعی برای نمایش لاگ‌ها
      ),
    );
  }

  // Perform a GET request
  Future<Response> getData(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    try {
      Response response = await dio.get(
        uri,
        queryParameters: queryParameters,
        options: Options(headers: headers),
      );
      return _handleResponse(response, uri);
    } on DioException catch (e) {
      return _handleDioException(e, uri);
    }
  }

  // Perform a POST request
  Future<Response> postData(
    String uri,
    dynamic data, {
    Map<String, dynamic>? headers,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('====> API Body: $data');
      }
      Response response = await dio.post(
        uri,
        data: data,
        options: Options(headers: headers),
      );
      return _handleResponse(response, uri);
    } on DioException catch (e) {
      return _handleDioException(e, uri);
    }
  }

  // Perform a POST request with multipart data (e.g., file upload)
  Future<Response> postMultipartData(
    String uri,
    Map<String, dynamic> data,
    List<MultipartBody> multipartBody, {
    Map<String, dynamic>? headers,
  }) async {
    try {
      FormData formData = FormData();
      // Add text fields
      data.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });
      // Add files
      for (MultipartBody multipart in multipartBody) {
        if (multipart.file != null) {
          String fileName = multipart.file!.name;
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
      if (kDebugMode) {
        debugPrint(
          '====> API Multipart POST: $uri with data: $data and ${multipartBody.length} file(s)',
        );
      }
      Response response = await dio.post(
        uri,
        data: formData,
        options: Options(headers: headers),
      );
      return _handleResponse(response, uri);
    } on DioException catch (e) {
      return _handleDioException(e, uri);
    }
  }

  // Perform a PATCH request with multipart data (e.g., file update)
  Future<Response> patchMultipartData(
    String uri,
    Map<String, String> data,
    List<MultipartBody> multipartBody, {
    Map<String, dynamic>? headers,
  }) async {
    try {
      FormData formData = FormData();
      // Add text fields
      data.forEach((key, value) {
        formData.fields.add(MapEntry(key, value));
      });
      // Add files
      for (MultipartBody multipart in multipartBody) {
        if (multipart.file != null) {
          String fileName = multipart.file!.name;
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
      if (kDebugMode) {
        debugPrint(
          '====> API Multipart PATCH: $uri with data: $data and ${multipartBody.length} file(s)',
        );
      }
      Response response = await dio.patch(
        uri,
        data: formData,
        options: Options(headers: headers),
      );
      return _handleResponse(response, uri);
    } on DioException catch (e) {
      return _handleDioException(e, uri);
    }
  }

  // Perform a PUT request
  Future<Response> putData(
    String uri,
    dynamic data, {
    Map<String, dynamic>? headers,
  }) async {
    try {
      Response response = await dio.put(
        uri,
        data: data,
        options: Options(headers: headers),
      );
      return _handleResponse(response, uri);
    } on DioException catch (e) {
      return _handleDioException(e, uri);
    }
  }

  // Perform a PATCH request
  Future<Response> patchData(
    String uri,
    dynamic data, {
    Map<String, dynamic>? headers,
  }) async {
    try {
      Response response = await dio.patch(
        uri,
        data: data,
        options: Options(headers: headers),
      );
      return _handleResponse(response, uri);
    } on DioException catch (e) {
      return _handleDioException(e, uri);
    }
  }

  // Perform a DELETE request
  Future<Response> deleteData(
    String uri, {
    Map<String, dynamic>? headers,
  }) async {
    try {
      Response response = await dio.delete(
        uri,
        options: Options(headers: headers),
      );
      return _handleResponse(response, uri);
    } on DioException catch (e) {
      return _handleDioException(e, uri);
    }
  }

  // Handle API responses (success or failure)
  Response _handleResponse(Response response, String uri) {
    if (kDebugMode) {
      debugPrint(
        '====> API Response: [${response.statusCode}] $uri\n${response.data}',
      );
    }
    if (response.statusCode == 200 || response.statusCode == 201) {
      return response;
    } else {
      // Convert HTTP error code to readable message
      String errorMessage = handleHttpError(response.statusCode!);
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        error: errorMessage,
      );
    }
  }

  // Handle Dio errors (network or server-related issues)
  Response _handleDioException(DioException error, String uri) {
    if (kDebugMode) {
      debugPrint('====> Error on $uri: ${error.message}');
    }
    // Provide an appropriate error message
    String errorMessage =
        error.response != null
            ? handleHttpError(error.response!.statusCode!)
            : 'Unable to connect to the server';
    throw DioException(
      requestOptions: error.requestOptions,
      error: errorMessage,
      response: error.response,
    );
  }
}

// Model for handling multipart file uploads
class MultipartBody {
  final String key;
  final XFile? file;
  MultipartBody(this.key, this.file);
}
