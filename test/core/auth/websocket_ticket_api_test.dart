import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/auth/auth_session.dart';
import 'package:asood/core/auth/token_storage.dart';
import 'package:asood/core/auth/websocket_ticket_api.dart';
import 'package:asood/core/constants/endpoints.dart';
import 'package:asood/core/http_client/api_client.dart';

class _MemoryStorage implements TokenStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String token) async {}
}

class _TicketClient extends DioClient {
  String? path;
  Object? body;
  dynamic responseData;

  _TicketClient()
    : super(
        appBaseUrl: 'https://example.test/api/v1/',
        authSession: AuthSession(_MemoryStorage()),
      );

  @override
  Future<Response> postData(
    String uri,
    dynamic data, {
    Map<String, dynamic>? headers,
  }) async {
    path = uri;
    body = data;
    return Response(
      requestOptions: RequestOptions(path: uri),
      statusCode: 201,
      data: responseData,
    );
  }
}

void main() {
  test(
    'chat ticket request never sends the long-lived auth token in data',
    () async {
      final client = _TicketClient();
      client.responseData = {
        'success': true,
        'code': 201,
        'data': {
          'ticket': 'opaque-one-use-value',
          'path': '/ws/chat/room-1/',
          'expires_in': 60,
        },
      };

      final ticket = await WebSocketTicketApi(
        dioClient: client,
      ).issueChatTicket('room-1');

      expect(client.path, Endpoints.webSocketTicket);
      expect(client.body, {'scope': 'chat', 'room_id': 'room-1'});
      expect((client.body as Map).containsKey('token'), isFalse);
      expect(ticket.path, '/ws/chat/room-1/');
      expect(ticket.expiresIn, 60);
    },
  );

  test('mismatched server path is rejected before opening a socket', () async {
    final client = _TicketClient();
    client.responseData = {
      'success': true,
      'code': 201,
      'data': {
        'ticket': 'opaque-one-use-value',
        'path': '/ws/chat/another-room/',
        'expires_in': 60,
      },
    };

    expect(
      () => WebSocketTicketApi(dioClient: client).issueChatTicket('room-1'),
      throwsFormatException,
    );
  });
}
