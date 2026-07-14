import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/constants/endpoints.dart';

class WebSocketTicket {
  final String ticket;
  final String path;
  final int expiresIn;

  const WebSocketTicket({
    required this.ticket,
    required this.path,
    required this.expiresIn,
  });
}

/// Exchanges the normal Authorization header for a one-use WebSocket ticket.
/// The long-lived auth token therefore never appears in a WebSocket URL.
class WebSocketTicketApi {
  final DioClient dioClient;

  WebSocketTicketApi({required this.dioClient});

  Future<WebSocketTicket> issueChatTicket(String roomId) async {
    final response = await dioClient.postData(Endpoints.webSocketTicket, {
      'scope': 'chat',
      'room_id': roomId,
    });
    final envelope = response.data;
    final data = envelope is Map ? envelope['data'] : null;
    if (data is! Map) {
      throw const FormatException('Missing WebSocket ticket payload');
    }

    final ticket = data['ticket']?.toString() ?? '';
    final path = data['path']?.toString() ?? '';
    final expiresIn = int.tryParse(data['expires_in']?.toString() ?? '');
    final expectedPath = '/ws/chat/$roomId/';
    if (ticket.isEmpty ||
        path != expectedPath ||
        expiresIn == null ||
        expiresIn < 1) {
      throw const FormatException('Invalid WebSocket ticket payload');
    }
    return WebSocketTicket(ticket: ticket, path: path, expiresIn: expiresIn);
  }
}
