import 'package:flutter_test/flutter_test.dart';
import 'package:asoud/core/ui/ui_status.dart';

void main() {
  group('UiStatus', () {
    group('UiIdle', () {
      test('should have correct properties', () {
        const status = UiIdle();
        
        expect(status.isIdle, isTrue);
        expect(status.isLoading, isFalse);
        expect(status.isSuccess, isFalse);
        expect(status.isError, isFalse);
      });

      test('should handle when pattern correctly', () {
        const status = UiIdle();
        
        final result = status.when(
          idle: () => 'idle state',
          loading: () => 'loading state',
          success: () => 'success state',
          error: (message) => 'error: $message',
        );
        
        expect(result, equals('idle state'));
      });
    });

    group('UiLoading', () {
      test('should have correct properties', () {
        const status = UiLoading();
        
        expect(status.isIdle, isFalse);
        expect(status.isLoading, isTrue);
        expect(status.isSuccess, isFalse);
        expect(status.isError, isFalse);
      });

      test('should handle when pattern correctly', () {
        const status = UiLoading();
        
        final result = status.when(
          idle: () => 'idle state',
          loading: () => 'loading state',
          success: () => 'success state',
          error: (message) => 'error: $message',
        );
        
        expect(result, equals('loading state'));
      });
    });

    group('UiSuccess', () {
      test('should have correct properties', () {
        const status = UiSuccess();
        
        expect(status.isIdle, isFalse);
        expect(status.isLoading, isFalse);
        expect(status.isSuccess, isTrue);
        expect(status.isError, isFalse);
      });

      test('should handle when pattern correctly', () {
        const status = UiSuccess();
        
        final result = status.when(
          idle: () => 'idle state',
          loading: () => 'loading state',
          success: () => 'success state',
          error: (message) => 'error: $message',
        );
        
        expect(result, equals('success state'));
      });
    });

    group('UiError', () {
      test('should have correct properties', () {
        const status = UiError('test error');
        
        expect(status.isIdle, isFalse);
        expect(status.isLoading, isFalse);
        expect(status.isSuccess, isFalse);
        expect(status.isError, isTrue);
        expect(status.message, equals('test error'));
      });

      test('should handle when pattern correctly', () {
        const status = UiError('network failed');
        
        final result = status.when(
          idle: () => 'idle state',
          loading: () => 'loading state',
          success: () => 'success state',
          error: (message) => 'error: $message',
        );
        
        expect(result, equals('error: network failed'));
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
  });
}
