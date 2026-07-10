import 'package:asood/features/chat/data/chat_api_service.dart';

/// REST-side repository for chat. Live delivery is handled by ChatSocket,
/// injected into the room bloc separately.
class ChatRepository {
  final ChatApiService api;
  ChatRepository(this.api);

  Future<dynamic> rooms() => api.rooms();

  Future<dynamic> createRoom(Map<String, dynamic> body) => api.createRoom(body);

  Future<dynamic> roomMessages(String roomId, {int page = 1}) =>
      api.roomMessages(roomId, page: page);

  Future<dynamic> sendMessageRest({
    required String roomId,
    required String content,
  }) => api.sendMessage(roomId: roomId, content: content);

  Future<dynamic> markAsRead(String messageId) => api.markAsRead(messageId);
}
