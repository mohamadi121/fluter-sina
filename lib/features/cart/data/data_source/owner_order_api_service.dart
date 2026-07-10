import 'package:dio/dio.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

/// Seller-side orders (`api/v1/owner/order/`, Token auth). Note the backend
/// paths have no trailing slash.
class OwnerOrderApiService {
  final DioClient dioClient;
  OwnerOrderApiService({required this.dioClient});

  Future list() async {
    try {
      final Response res = await dioClient.getData('owner/order/list');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future detail(String id) async {
    try {
      final Response res = await dioClient.getData('owner/order/$id');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  /// Verify (accept/reject) an order. Body: {id, verified, description}.
  Future verify({
    required String id,
    required bool verified,
    String description = '',
  }) async {
    try {
      final Response res = await dioClient.postData('owner/order/verify', {
        'id': id,
        'verified': verified,
        'description': description,
      });
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
}
