import 'package:dio/dio.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

/// Analytics dashboard (`api/v1/analytics/dashboard/`, Token auth).
class AnalyticsApiService {
  final DioClient dioClient;
  AnalyticsApiService({required this.dioClient});

  Future dashboard() async {
    try {
      final Response res = await dioClient.getData('analytics/dashboard/');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
}
