import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/constants/endpoints.dart';
import 'package:dio/dio.dart';

import 'package:asood/core/helper/secure_storage.dart';
import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

class AuthApiService {
  final DioClient dioClient;
  AuthApiService({required this.dioClient});

  // Send verification code to user
  Future userAuth(String number) async {
    var body = {"mobile_number": number};

    try {
      Response res = await dioClient.postData(
        Endpoints.loginCreate,
        body,
        headers: Endpoints.simpleHeader,
      );
      return apiStatus(res);
    } catch (e) {
      return customApiStatus();
    }
  }

  // Verify user SMS code
  Future verifyUser(String number, String code) async {
    var body = {"mobile_number": number, 'pin': code};

    try {
      Response res = await dioClient.postData(
        Endpoints.loginVerify,
        body,
        headers: Endpoints.simpleHeader,
      );
      return apiStatus(res);
    } catch (e) {
      return customApiStatus();
    }
  }

  // Get user advertisements
  Future getAdvertises() async {
    try {
      Response res = await dioClient.getData(Endpoints.userAdvertise);
      return apiStatus(res);
    } catch (e) {
      return customApiStatus();
    }
  }

  // Get user contacts
  Future getContacts() async {
    try {
      Response res = await dioClient.getData(Endpoints.userContact);
      return apiStatus(res);
    } catch (e) {
      return customApiStatus();
    }
  }

  // Log out user
  Future logout() async {
    try {
      String? token = await SecureStorage.readSecureStorage(Keys.token);

      Response res = await dioClient.getData(
        Endpoints.logout,
        headers: {'Authorization': 'Token $token'},
      );

      return apiStatus(res);
    } catch (e) {
      return customApiStatus();
    }
  }
}
