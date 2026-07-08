import 'package:dio/dio.dart';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/constants/endpoints.dart';
import 'package:asood/core/helper/secure_storage.dart';
import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

/// Auth against the backend's pin flow (DRF TokenAuthentication).
/// `pin/verify/` returns `data: {token: <key>}`; there is no refresh token
/// and no server-side logout endpoint, so logout is purely local.
class AuthApiService {
  final DioClient dioClient;
  AuthApiService({required this.dioClient});

  Future userAuth(String number) async {
    final body = {"mobile_number": number};

    try {
      final Response res = await dioClient.postData(
        Endpoints.loginCreate,
        body,
        headers: Endpoints.simpleHeader,
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future verifyUser(String number, String code) async {
    final body = {"mobile_number": number, 'pin': code};

    try {
      final res = await dioClient.postData(
        Endpoints.loginVerify,
        body,
        headers: Endpoints.simpleHeader,
      );

      final result = apiStatus(res);
      if (result is Success) {
        final token = (result.response as Map?)?['token'];
        if (token == null) {
          return Failure(
            code: res.statusCode,
            errorResponse: 'پاسخ ورود فاقد توکن است',
            kind: FailureKind.parsing,
          );
        }
        await SecureStorage.writeSecureStorage(Keys.token, token.toString());
      }
      return result;
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future getAdvertises() async {
    try {
      final Response res = await dioClient.getData(Endpoints.userAdvertise);
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future logout() async {
    await SecureStorage.deleteSecureStorage(Keys.token);
    return Success(code: 200, response: {}, message: 'Logged out');
  }
}
