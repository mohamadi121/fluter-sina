import 'package:dio/dio.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

class ProfileApiService {
  final DioClient dioClient;

  ProfileApiService({required this.dioClient});

  static const String _path = 'user/profile/';

  Future getProfile() async {
    try {
      final Response response = await dioClient.getData(_path);
      return apiStatus(response);
    } catch (error) {
      return apiFailure(error);
    }
  }

  Future updateProfile(Map<String, dynamic> body) async {
    try {
      final Response response = await dioClient.putData(_path, body);
      return apiStatus(response);
    } catch (error) {
      return apiFailure(error);
    }
  }
}
