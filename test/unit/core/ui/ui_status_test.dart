import 'package:flutter_test/flutter_test.dart';
import 'package:asoud/core/ui/ui_status.dart';

void main() {
  group('UiStatus', () {
    group('UiIdle', () {
      test('should create idle status', () {
        const status = UiIdle();
        
        expect(status.isIdle, isTrue);
        expect(status.isLoading, isFalse);
        expect(status.isSuccess, isFalse);
        expect(status.isError, isFalse);
      });

      test('should handle when correctly for idle', () {
        const status = UiIdle();
        
        final result = status.when(
          idle: () => 'idle',
          loading: () => 'loading',
          success: () => 'success',
          error: (message) => 'error: $message',
        );
        
        expect(result, equals('idle'));
      });
    });

    group('UiLoading', () {
      test('should create loading status', () {
        const status = UiLoading();
        
        expect(status.isIdle, isFalse);
        expect(status.isLoading, isTrue);
        expect(status.isSuccess, isFalse);
        expect(status.isError, isFalse);
      });

      test('should handle when correctly for loading', () {
        const status = UiLoading();
        
        final result = status.when(
          idle: () => 'idle',
          loading: () => 'loading',
          success: () => 'success',
          error: (message) => 'error: $message',
        );
        
        expect(result, equals('loading'));
      });
    });

    group('UiSuccess', () {
      test('should create success status', () {
        const status = UiSuccess();
        
        expect(status.isIdle, isFalse);
        expect(status.isLoading, isFalse);
        expect(status.isSuccess, isTrue);
        expect(status.isError, isFalse);
      });

      test('should handle when correctly for success', () {
        const status = UiSuccess();
        
        final result = status.when(
          idle: () => 'idle',
          loading: () => 'loading',
          success: () => 'success',
          error: (message) => 'error: $message',
        );
        
        expect(result, equals('success'));
      });
    });

    group('UiError', () {
      test('should create error status with message', () {
        const status = UiError('Test error message');
        
        expect(status.isIdle, isFalse);
        expect(status.isLoading, isFalse);
        expect(status.isSuccess, isFalse);
        expect(status.isError, isTrue);
        expect(status.message, equals('Test error message'));
      });

      test('should handle when correctly for error', () {
        const status = UiError('Network failed');
        
        final result = status.when(
          idle: () => 'idle',
          loading: () => 'loading',
          success: () => 'success',
          error: (message) => 'error: $message',
        );
        
        expect(result, equals('error: Network failed'));
      });
    });

    group('Type checks', () {
      test('should correctly identify status types', () {
        const idle = UiIdle();
        const loading = UiLoading();
        const success = UiSuccess();
        const error = UiError('test');

        expect(idle is UiIdle, isTrue);
        expect(loading is UiLoading, isTrue);
        expect(success is UiSuccess, isTrue);
        expect(error is UiError, isTrue);

        expect(idle is UiLoading, isFalse);
        expect(loading is UiSuccess, isFalse);
        expect(success is UiError, isFalse);
        expect(error is UiIdle, isFalse);
      });
    });

    group('Equality', () {
      test('should handle equality correctly', () {
        const idle1 = UiIdle();
        const idle2 = UiIdle();
        const loading1 = UiLoading();
        const loading2 = UiLoading();
        const success1 = UiSuccess();
        const success2 = UiSuccess();
        const error1 = UiError('same message');
        const error2 = UiError('same message');
        const error3 = UiError('different message');

        expect(idle1, equals(idle2));
        expect(loading1, equals(loading2));
        expect(success1, equals(success2));
        expect(error1, equals(error2));
        expect(error1, isNot(equals(error3)));
      });
    });
  });
}
