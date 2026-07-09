import 'package:dio/dio.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

/// Buyer-side public market browsing
/// (GET user/market/public/list/, supports ?search=).
class PublicMarketApiService {
  final DioClient dioClient;
  PublicMarketApiService({required this.dioClient});

  Future list({String? search}) async {
    try {
      final Response res = await dioClient.getData(
        'user/market/public/list/',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
}
