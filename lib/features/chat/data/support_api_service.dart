import 'package:dio/dio.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

/// Support tickets (`api/v1/chat/support/tickets/`, Token auth). Creating a
/// ticket spawns a chat room (`chat_room_id`) the user can message in.
class SupportApiService {
  final DioClient dioClient;
  SupportApiService({required this.dioClient});

  Future tickets() async {
    try {
      final Response res = await dioClient.getData('chat/support/tickets/');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future createTicket({
    required String subject,
    required String description,
    String category = 'general',
    String priority = 'medium',
  }) async {
    try {
      final Response res = await dioClient.postData('chat/support/tickets/', {
        'subject': subject,
        'description': description,
        'category': category,
        'priority': priority,
      });
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
}
