import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:asood/core/auth/auth_session.dart';
import 'package:asood/core/constants/endpoints.dart';
import 'package:asood/core/logging/app_logger.dart';

/// Live chat transport over the backend's Channels WebSocket
/// (`ws/chat/<room_id>/?token=<key>`). Emits decoded server frames and
/// exposes helpers for the client→server frame types the consumer handles.
class ChatSocket {
  final AuthSession authSession;

  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _controller;
  StreamSubscription? _sub;

  ChatSocket({required this.authSession});

  Stream<Map<String, dynamic>> get frames =>
      _controller?.stream ?? const Stream.empty();

  bool get isConnected => _channel != null;

  /// Builds `wss://host/ws/chat/{roomId}/?token={key}` from the REST base URL.
  Uri _socketUri(String roomId) {
    final base = Uri.parse(Endpoints.baseUrl); // https://host/api/v1/
    final scheme = base.scheme == 'https' ? 'wss' : 'ws';
    final token = authSession.token ?? '';
    return Uri(
      scheme: scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: '/ws/chat/$roomId/',
      queryParameters: {'token': token},
    );
  }

  void connect(String roomId) {
    disconnect();
    final uri = _socketUri(roomId);
    AppLogger.info('chat_ws', 'connecting to ${uri.path}');

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controller = controller;

    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _sub = channel.stream.listen(
        (event) {
          try {
            final decoded = jsonDecode(event as String);
            if (decoded is Map<String, dynamic>) {
              controller.add(decoded);
            }
          } catch (e) {
            AppLogger.warning('chat_ws', 'undecodable frame', e);
          }
        },
        onError: (error, st) {
          AppLogger.warning('chat_ws', 'socket error', error, st);
          controller.add({'type': 'socket_error'});
        },
        onDone: () {
          AppLogger.info('chat_ws', 'socket closed');
          if (!controller.isClosed) {
            controller.add({'type': 'socket_closed'});
          }
        },
      );
    } catch (e, st) {
      AppLogger.error('chat_ws', 'connect failed', e, st);
      controller.add({'type': 'socket_error'});
    }
  }

  void sendMessage(String content, {String messageType = 'text'}) {
    _send({
      'type': 'chat_message',
      'content': content,
      'message_type': messageType,
    });
  }

  void sendTyping({required bool typing}) {
    _send({'type': typing ? 'typing' : 'stop_typing'});
  }

  void markAsRead(String messageId) {
    _send({'type': 'mark_as_read', 'message_id': messageId});
  }

  void _send(Map<String, dynamic> frame) {
    final channel = _channel;
    if (channel == null) {
      AppLogger.warning('chat_ws', 'send while disconnected: ${frame['type']}');
      return;
    }
    channel.sink.add(jsonEncode(frame));
  }

  void disconnect() {
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
    _controller?.close();
    _controller = null;
  }
}
