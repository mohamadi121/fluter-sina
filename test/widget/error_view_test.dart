import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asoud/core/widgets/atomic/error_view.dart';
import 'package:asoud/core/network/app_error.dart';

void main() {
  group('ErrorView Widget', () {
    testWidgets('should display error message and icon', (tester) async {
      const error = BusinessError(message: 'خطای تست');
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(error: error),
          ),
        ),
      );

      // بررسی وجود آیکون خطا
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      
      // بررسی وجود پیام خطا
      expect(find.text('خطای تست'), findsOneWidget);
      
      // بررسی عدم وجود دکمه تلاش دوباره (چون onRetry null است)
      expect(find.text('تلاش دوباره'), findsNothing);
    });

    testWidgets('should display retry button when onRetry is provided', (tester) async {
      const error = NetworkError(message: 'خطای شبکه');
      var retryPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(
              error: error,
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      // بررسی وجود آیکون خطا
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      
      // بررسی وجود پیام خطا
      expect(find.text('خطای شبکه'), findsOneWidget);
      
      // بررسی وجود دکمه تلاش دوباره
      expect(find.text('تلاش دوباره'), findsOneWidget);
      
      // بررسی وجود آیکون refresh در دکمه
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      
      // تست کلیک روی دکمه
      await tester.tap(find.text('تلاش دوباره'));
      expect(retryPressed, isTrue);
    });

    testWidgets('should handle different error types correctly', (tester) async {
      const unknownError = UnknownError(message: 'خطای ناشناخته');
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(error: unknownError),
          ),
        ),
      );

      expect(find.text('خطای ناشناخته'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should use theme colors correctly', (tester) async {
      const error = BusinessError(message: 'تست تم');
      
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.dark(
              error: Colors.red,
            ),
          ),
          home: const Scaffold(
            body: ErrorView(error: error),
          ),
        ),
      );

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(iconWidget.color, equals(Colors.red));
    });

    testWidgets('should center content properly', (tester) async {
      const error = BusinessError(message: 'تست مرکز');
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(error: error),
          ),
        ),
      );

      // بررسی وجود Center widget
      expect(find.byType(Center), findsOneWidget);
      
      // بررسی وجود Column با mainAxisSize.min
      final columnWidget = tester.widget<Column>(find.byType(Column));
      expect(columnWidget.mainAxisSize, equals(MainAxisSize.min));
    });

    testWidgets('should handle long error messages correctly', (tester) async {
      const longMessage = 'این یک پیام خطای خیلی طولانی است که باید به درستی نمایش داده شود و در مرکز صفحه قرار گیرد';
      const error = BusinessError(message: longMessage);
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorView(error: error),
          ),
        ),
      );

      expect(find.text(longMessage), findsOneWidget);
      
      // بررسی تراز متن در مرکز
      final textWidget = tester.widget<Text>(find.text(longMessage));
      expect(textWidget.textAlign, equals(TextAlign.center));
    });
  });
}
