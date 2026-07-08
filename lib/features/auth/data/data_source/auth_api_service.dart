import 'package:dio/dio.dart';

import 'package:asood/core/constants/endpoints.dart';
import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

/// Auth against the backend's pin flow (DRF TokenAuthentication).
/// `pin/verify/` returns `data: {token: <key>}`; there is no refresh token
/// and no server-side logout endpoint. Token persistence lives in
/// AuthSession, not here.
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
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
}
