import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/http_client/api_status.dart';

Response<dynamic> _response(dynamic data, int status) {
  return Response(
    requestOptions: RequestOptions(path: '/test/'),
    data: data,
    statusCode: status,
  );
}

DioException _dioError({Response<dynamic>? response}) {
  return DioException(
    requestOptions: RequestOptions(path: '/test/'),
    response: response,
    type:
        response == null
            ? DioExceptionType.connectionError
            : DioExceptionType.badResponse,
  );
}

void main() {
  group('apiStatus (2xx envelope)', () {
    test('success envelope maps to Success with data and message', () {
      final result = apiStatus(
        _response({
          'success': true,
          'code': 200,
          'data': {'token': 'abc'},
          'message': 'ok',
        }, 200),
      );

      expect(result, isA<Success>());
      final success = result as Success;
      expect(success.code, 200);
      expect((success.response as Map)['token'], 'abc');
      expect(success.message, 'ok');
    });

    test('failure envelope maps to validation Failure with backend detail', () {
      final result = apiStatus(
        _response({
          'success': false,
          'code': 400,
          'error': {'code': 'validation_error', 'detail': 'pin is required'},
        }, 200),
      );

      expect(result, isA<Failure>());
      final failure = result as Failure;
      expect(failure.kind, FailureKind.validation);
      expect(failure.errorResponse, 'pin is required');
    });

    test('non-map body maps to parsing Failure', () {
      final result = apiStatus(_response('<html>gateway</html>', 200));

      expect(result, isA<Failure>());
      expect((result as Failure).kind, FailureKind.parsing);
    });
  });

  group('apiFailure (thrown errors)', () {
    test('no response means network failure', () {
      final failure = apiFailure(_dioError());

      expect(failure.kind, FailureKind.network);
      expect(failure.code, isNull);
    });

    test('401 with envelope keeps backend detail and is auth error', () {
      final failure = apiFailure(
        _dioError(
          response: _response({
            'success': false,
            'code': 401,
            'error': {'code': 'pin_not_valid', 'detail': 'Pin not valid'},
          }, 401),
        ),
      );

      expect(failure.kind, FailureKind.unauthorized);
      expect(failure.isAuthError, isTrue);
      expect(failure.errorResponse, 'Pin not valid');
      expect(failure.code, 401);
    });

    test('404 without envelope falls back to generic message', () {
      final failure = apiFailure(
        _dioError(response: _response('not found', 404)),
      );

      expect(failure.kind, FailureKind.notFound);
      expect(failure.errorResponse, isNotNull);
    });

    test('500 maps to server failure', () {
      final failure = apiFailure(
        _dioError(response: _response({'detail': 'boom'}, 500)),
      );

      expect(failure.kind, FailureKind.server);
      expect(failure.errorResponse, 'boom');
    });

    test('non-dio error maps to unknown failure', () {
      final failure = apiFailure(StateError('oops'));

      expect(failure.kind, FailureKind.unknown);
    });
  });
}
