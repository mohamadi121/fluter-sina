import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/auth/auth_session.dart';
import 'package:asood/core/auth/token_storage.dart';
import 'package:asood/core/constants/endpoints.dart';
import 'package:asood/core/http_client/api_client.dart';
import 'package:asood/core/http_client/api_status.dart';
import 'package:asood/features/market/data/data_source/product_api_service.dart';

class _MemoryTokenStorage implements TokenStorage {
  @override
  Future<void> clear() async {}

  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String token) async {}
}

class _RecordingDioClient extends DioClient {
  String? requestedPath;
  Map<String, dynamic>? requestedQuery;

  _RecordingDioClient()
    : super(
        appBaseUrl: 'https://example.test/api/v1/',
        authSession: AuthSession(_MemoryTokenStorage()),
      );

  @override
  Future<Response> getData(
    String uri, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
  }) async {
    requestedPath = uri;
    requestedQuery = queryParameters;
    return Response(
      requestOptions: RequestOptions(path: uri),
      statusCode: 200,
      data: {
        'success': true,
        'code': 200,
        'data': {'id': 'product-1', 'name': 'Public product'},
      },
    );
  }
}

void main() {
  test('product detail uses the public query endpoint', () async {
    final client = _RecordingDioClient();
    final service = ProductApiService(dioClient: client);

    final result = await service.getProductById('product-1');

    expect(client.requestedPath, 'products');
    expect(
      Uri.parse(Endpoints.baseUrl).resolve(client.requestedPath!).path,
      '/api/v1/products',
    );
    expect(client.requestedQuery, {'id': 'product-1'});
    expect(result, isA<Success>());
    final data = (result as Success).response as Map<String, dynamic>;
    expect(data['name'], 'Public product');
  });
}
