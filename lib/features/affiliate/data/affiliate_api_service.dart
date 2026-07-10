import 'package:dio/dio.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

/// Affiliate/marketer products (`api/v1/user/affiliate/`, Token auth).
class AffiliateApiService {
  final DioClient dioClient;
  AffiliateApiService({required this.dioClient});

  static const String _base = 'user/affiliate/';

  /// Products the user can affiliate-market.
  Future availableProducts() async {
    try {
      final Response res = await dioClient.getData('${_base}products/');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  /// The user's own affiliate products for a given market.
  Future myProducts(String marketId) async {
    try {
      final Response res = await dioClient.getData('${_base}list/$marketId/');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future create(Map<String, dynamic> body) async {
    try {
      final Response res = await dioClient.postData('${_base}create/', body);
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future delete(String id) async {
    try {
      final Response res = await dioClient.deleteData('$_base$id/delete/');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
}
