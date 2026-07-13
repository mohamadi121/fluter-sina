import 'package:dio/dio.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

class ReferralApiService {
  final DioClient dioClient;

  ReferralApiService({required this.dioClient});

  static const String _base = 'user/referral/';

  Future summary() async {
    try {
      final Response response = await dioClient.getData(_base);
      return apiStatus(response);
    } catch (error) {
      return apiFailure(error);
    }
  }

  Future applyCode(String code) async {
    try {
      final Response response = await dioClient.postData('${_base}create/', {
        'code': code,
      });
      return apiStatus(response);
    } catch (error) {
      return apiFailure(error);
    }
  }
}
