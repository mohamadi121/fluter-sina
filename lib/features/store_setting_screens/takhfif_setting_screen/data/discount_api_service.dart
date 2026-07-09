import 'package:dio/dio.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

/// Owner discount codes (apps/discount, mounted at api/v1/discount/).
/// create body: {content_type: 'market'|'product', object_id, percentage,
/// expiry, limitation?, users?, position?} — owner is set server-side.
class DiscountApiService {
  final DioClient dioClient;
  DiscountApiService({required this.dioClient});

  Future list() async {
    try {
      final Response res = await dioClient.getData('discount/owner/list/');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future create(Map<String, dynamic> body) async {
    try {
      final Response res = await dioClient.postData(
        'discount/owner/create/',
        body,
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future delete(String discountId) async {
    try {
      final Response res = await dioClient.deleteData(
        'discount/owner/delete/$discountId/',
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
}
