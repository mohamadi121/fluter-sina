import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_client.dart';

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

const _storageChannel = MethodChannel(
  'plugins.it_nomads.com/flutter_secure_storage',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Map<String, String> fakeStorage = {};

  setUp(() {
    fakeStorage.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_storageChannel, (call) async {
          final args = Map<String, dynamic>.from(call.arguments as Map);
          switch (call.method) {
            case 'read':
              return fakeStorage[args['key']];
            case 'write':
              fakeStorage[args['key'] as String] = args['value'] as String;
              return null;
            case 'delete':
              fakeStorage.remove(args['key']);
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_storageChannel, null);
  });

  DioClient buildClient(_CapturingAdapter adapter) {
    final client = DioClient(appBaseUrl: 'https://example.test/api/v1/');
    client.dio.httpClientAdapter = adapter;
    return client;
  }

  test('sends DRF Token header when a token is stored', () async {
    fakeStorage['token'] = 'abc123';
    final adapter = _CapturingAdapter();
    final client = buildClient(adapter);

    await client.getData('user/order/orders');

    expect(adapter.lastRequest?.headers['Authorization'], 'Token abc123');
  });

  test('sends no Authorization header when no token is stored', () async {
    final adapter = _CapturingAdapter();
    final client = buildClient(adapter);

    await client.getData('category/group/list/');

    expect(adapter.lastRequest?.headers.containsKey('Authorization'), isFalse);
  });

  test('401 clears the stored token and propagates the error', () async {
    fakeStorage['token'] = 'expired';
    final adapter =
        _CapturingAdapter()
          ..statusCode = 401
          ..body =
              '{"success": false, "code": 401, "error": {"code": "x", "detail": "bad token"}}';
    final client = buildClient(adapter);

    await expectLater(
      client.getData('wallet/balance/'),
      throwsA(isA<DioException>()),
    );
    expect(fakeStorage.containsKey('token'), isFalse);
  });
}
