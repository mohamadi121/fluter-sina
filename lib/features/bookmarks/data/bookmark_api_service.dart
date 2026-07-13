import 'package:dio/dio.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

/// Backend contract (apps/market/views/user_views.py MarketBookmarkAPIView):
/// GET  user/market/bookmark/       -> envelope, data = list of markets
/// PUT  user/market/bookmark/{pk}/  -> idempotently sets bookmark state.
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

  Future setBookmarked(String marketId, bool bookmarked) async {
    try {
      final Response res = await dioClient.putData(
        'user/market/bookmark/$marketId/',
        {'bookmarked': bookmarked},
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
}
