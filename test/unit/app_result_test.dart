import 'package:flutter_test/flutter_test.dart';
import 'package:asoud/core/network/app_result.dart';
import 'package:asoud/core/network/app_error.dart';

void main() {
  group('AppResult', () {
    group('Success', () {
      test('should create Success instance correctly', () {
        const data = 'test data';
        const result = Success(data);

        expect(result.data, equals(data));
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.dataOrNull, equals(data));
        expect(result.errorOrNull, isNull);
      });

      test('should handle when pattern correctly for Success', () {
        const data = 42;
        const result = Success(data);

        final output = result.when(
          success: (data) => 'success: $data',
          failure: (error) => 'failure: ${error.message}',
        );

        expect(output, equals('success: 42'));
      });

      test('should handle fold pattern correctly for Success', () {
        const data = 'hello';
        const result = Success(data);

        final output = result.fold(
          success: (data) => data.toUpperCase(),
          failure: (error) => 'error',
        );

        expect(output, equals('HELLO'));
      });
    });

    group('Failure', () {
      test('should create Failure instance correctly', () {
        final error = UnknownError(message: 'test error');
        final result = Failure<String>(error);

        expect(result.error, equals(error));
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.dataOrNull, isNull);
        expect(result.errorOrNull, equals(error));
      });

      test('should handle when pattern correctly for Failure', () {
        final error = BusinessError(message: 'business error');
        final result = Failure<int>(error);

        final output = result.when(
          success: (data) => 'success: $data',
          failure: (error) => 'failure: ${error.message}',
        );

        expect(output, equals('failure: business error'));
      });

      test('should handle fold pattern correctly for Failure', () {
        final error = NetworkError(message: 'network error');
        final result = Failure<String>(error);

        final output = result.fold(
          success: (data) => data.toUpperCase(),
          failure: (error) => 'ERROR: ${error.message}',
        );

        expect(output, equals('ERROR: network error'));
      });
    });

    group('Type Safety', () {
      test('should maintain type safety across transformations', () {
        const stringResult = Success<String>('test');
        const intResult = Success<int>(123);
        final errorResult = Failure<bool>(UnknownError(message: 'error'));

        expect(stringResult.dataOrNull, isA<String>());
        expect(intResult.dataOrNull, isA<int>());
        expect(errorResult.dataOrNull, isNull);
        expect(errorResult.errorOrNull, isA<AppError>());
      });
    });
  });
}
