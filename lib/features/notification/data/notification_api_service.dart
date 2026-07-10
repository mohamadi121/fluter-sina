import 'package:dio/dio.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

/// Notifications (`api/v1/notifications/`, DRF viewset, Token auth).
class NotificationApiService {
  final DioClient dioClient;
  NotificationApiService({required this.dioClient});

  Future list() async {
    try {
      final Response res = await dioClient.getData('notifications/');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future unreadCount() async {
    try {
      final Response res = await dioClient.getData(
        'notifications/unread_count/',
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future markAsRead(String id) async {
    try {
      final Response res = await dioClient.postData(
        'notifications/$id/mark_as_read/',
        {},
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future markAllAsRead() async {
    try {
      final Response res = await dioClient.postData(
        'notifications/mark_all_as_read/',
        {},
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
}
