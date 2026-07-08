import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/auth/auth_session.dart';
import 'package:asood/core/http_client/api_client.dart';

import '../auth/in_memory_token_storage.dart';

class _CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;
  int statusCode = 200;
  String body = '{"success": true, "code": 200, "data": {}, "message": "ok"}';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      body,
      statusCode,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  Future<AuthSession> buildSession([String? token]) async {
    final session = AuthSession(InMemoryTokenStorage(token));
    await session.hydrate();
    return session;
  }

  DioClient buildClient(AuthSession session, _CapturingAdapter adapter) {
    final client = DioClient(
      appBaseUrl: 'https://example.test/api/v1/',
      authSession: session,
    );
    client.dio.httpClientAdapter = adapter;
    return client;
  }

  test('sends DRF Token header when authenticated', () async {
    final session = await buildSession('abc123');
    final adapter = _CapturingAdapter();
    final client = buildClient(session, adapter);

    await client.getData('user/order/orders');

    expect(adapter.lastRequest?.headers['Authorization'], 'Token abc123');
  });

  test('sends no Authorization header when anonymous', () async {
    final session = await buildSession();
    final adapter = _CapturingAdapter();
    final client = buildClient(session, adapter);

    await client.getData('category/group/list/');

    expect(adapter.lastRequest?.headers.containsKey('Authorization'), isFalse);
  });

  test('401 clears the session and propagates the error', () async {
    final session = await buildSession('expired');
    final adapter =
        _CapturingAdapter()
          ..statusCode = 401
          ..body =
              '{"success": false, "code": 401, "error": {"code": "x", "detail": "bad token"}}';
    final client = buildClient(session, adapter);

    await expectLater(
      client.getData('wallet/balance/'),
      throwsA(isA<DioException>()),
    );
    expect(session.isAuthenticated, isFalse);
  });
}
