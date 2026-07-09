import 'package:dio/dio.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

/// Backend contract (apps/market/views/user_views.py MarketBookmarkAPIView):
/// GET  user/market/bookmark/       -> envelope, data = list of markets
/// POST user/market/bookmark/{pk}/  -> toggles; message says which way.
class BookmarkApiService {
  final DioClient dioClient;
  BookmarkApiService({required this.dioClient});

  Future list() async {
    try {
      final Response res = await dioClient.getData('user/market/bookmark/');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future toggle(String marketId) async {
    try {
      final Response res = await dioClient.postData(
        'user/market/bookmark/$marketId/',
        {},
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
}
