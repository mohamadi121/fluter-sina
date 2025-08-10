import 'package:flutter_test/flutter_test.dart';
import 'package:asoud/core/network/app_result.dart';
import 'package:asoud/core/network/app_error.dart';

void main() {
  group('AppResult', () {
    group('Success', () {
      test('should create success result with data', () {
        const result = Success<String>('test data');
        
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.dataOrNull, equals('test data'));
        expect(result.errorOrNull, isNull);
      });

      test('should handle fold correctly for success', () {
        const result = Success<int>(42);
        
        final output = result.fold(
          success: (data) => 'Success: $data',
          failure: (error) => 'Error: ${error.message}',
        );
        
        expect(output, equals('Success: 42'));
      });

      test('should handle when correctly for success', () {
        const result = Success<String>('hello');
        
        final output = result.when(
          success: (data) => data.toUpperCase(),
          failure: (error) => 'ERROR',
        );
        
        expect(output, equals('HELLO'));
      });
    });

    group('Failure', () {
      test('should create failure result with error', () {
        final error = BusinessError(message: 'Test error');
        final result = Failure<String>(error);
        
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.dataOrNull, isNull);
        expect(result.errorOrNull, equals(error));
      });

      test('should handle fold correctly for failure', () {
        final error = NetworkError(message: 'Network failed');
        final result = Failure<int>(error);
        
        final output = result.fold(
          success: (data) => 'Success: $data',
          failure: (error) => 'Error: ${error.message}',
        );
        
        expect(output, equals('Error: Network failed'));
      });

      test('should handle when correctly for failure', () {
        final error = UnknownError(message: 'Unknown error');
        final result = Failure<String>(error);
        
        final output = result.when(
          success: (data) => data.toUpperCase(),
          failure: (error) => 'FAILED: ${error.message}',
        );
        
        expect(output, equals('FAILED: Unknown error'));
      });
    });

    group('Type safety', () {
      test('should maintain type safety with different data types', () {
        const stringResult = Success<String>('text');
        const intResult = Success<int>(123);
        const boolResult = Success<bool>(true);
        
        expect(stringResult.dataOrNull, isA<String>());
        expect(intResult.dataOrNull, isA<int>());
        expect(boolResult.dataOrNull, isA<bool>());
      });

      test('should work with nullable types', () {
        const result = Success<String?>(null);
        
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull, isNull);
      });
    });
  });
}
