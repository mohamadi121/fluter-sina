import 'package:dio/dio.dart';

import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';

/// REST surface of the chat app (`api/v1/chat/`, Token auth). Used for room
/// lists and message history/pagination; live delivery goes over the socket.
class ChatApiService {
  final DioClient dioClient;
  ChatApiService({required this.dioClient});

  Future rooms() async {
    try {
      final Response res = await dioClient.getData('chat/rooms/');
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future createRoom(Map<String, dynamic> body) async {
    try {
      final Response res = await dioClient.postData('chat/rooms/', body);
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  /// Paginated history for a room; response is `{results, count, page, ...}`.
  Future roomMessages(String roomId, {int page = 1, int pageSize = 50}) async {
    try {
      final Response res = await dioClient.getData(
        'chat/messages/room_messages/',
        queryParameters: {
          'room_id': roomId,
          'page': page,
          'page_size': pageSize,
        },
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  /// Fallback send over REST (used when the socket is not connected).
  Future sendMessage({
    required String roomId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      final Response res = await dioClient.postData('chat/messages/', {
        'chat_room_id': roomId,
        'content': content,
        'message_type': messageType,
      });
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future markAsRead(String messageId) async {
    try {
      final Response res = await dioClient.postData(
        'chat/messages/$messageId/mark_as_read/',
        {},
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future participants(String roomId) async {
    try {
      final Response res = await dioClient.getData(
        'chat/rooms/$roomId/participants/',
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future addParticipant(
    String roomId, {
    required String mobileNumber,
    String role = 'member',
  }) async {
    try {
      final Response res = await dioClient.postData(
        'chat/rooms/$roomId/participants/',
        {'mobile_number': mobileNumber, 'role': role},
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future changeParticipantRole(String roomId, int userId, String role) async {
    try {
      final Response res = await dioClient.patchData(
        'chat/rooms/$roomId/participants/$userId/',
        {'role': role},
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future removeParticipant(String roomId, int userId) async {
    try {
      final Response res = await dioClient.deleteData(
        'chat/rooms/$roomId/participants/$userId/',
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future leaveRoom(String roomId) async {
    try {
      final Response res = await dioClient.postData(
        'chat/rooms/$roomId/leave/',
        {},
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }

  Future transferOwnership(String roomId, int userId) async {
    try {
      final Response res = await dioClient.postData(
        'chat/rooms/$roomId/transfer-ownership/',
        {'user_id': userId},
      );
      return apiStatus(res);
    } catch (e) {
      return apiFailure(e);
    }
  }
}
