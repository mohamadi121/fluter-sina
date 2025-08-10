import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asoud/core/widgets/atomic/error_view.dart';
import 'package:asoud/core/network/app_error.dart';

void main() {
  group('ErrorView Widget', () {
    testWidgets('displays error message and icon', (WidgetTester tester) async {
      final error = BusinessError(message: 'Test error message');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(error: error),
          ),
        ),
      );

      expect(find.text('Test error message'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('تلاش دوباره'), findsNothing);
    });

    testWidgets('displays retry button when onRetry is provided', (WidgetTester tester) async {
      final error = NetworkError(message: 'Network error');
      bool retryPressed = false;
      
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

      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('تلاش دوباره'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      await tester.tap(find.text('تلاش دوباره'));
      await tester.pump();

      expect(retryPressed, isTrue);
    });

    testWidgets('does not display retry button when onRetry is null', (WidgetTester tester) async {
      final error = UnknownError(message: 'Unknown error');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(error: error),
          ),
        ),
      );

      expect(find.text('Unknown error'), findsOneWidget);
      expect(find.text('تلاش دوباره'), findsNothing);
      expect(find.byIcon(Icons.refresh), findsNothing);
    });

    testWidgets('applies correct styling and layout', (WidgetTester tester) async {
      const error = BusinessError(message: 'Test error for styling');

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: ErrorView(error: error),
          ),
        ),
      );

      // Check that Center widget exists (there might be multiple)
      final centerFinder = find.byType(Center);
      expect(centerFinder, findsAtLeastNWidgets(1));

      // Check that there are Padding widgets for layout
      final paddingFinders = find.byType(Padding);
      expect(paddingFinders.evaluate().length, greaterThanOrEqualTo(1));

      final columnWidget = tester.widget<Column>(find.byType(Column));
      expect(columnWidget.mainAxisSize, MainAxisSize.min);
      expect(columnWidget.children.length, greaterThanOrEqualTo(3));

      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(iconWidget.size, 56);
    });    testWidgets('handles different error types correctly', (WidgetTester tester) async {
      final errors = [
        BusinessError(message: 'Business logic error'),
        NetworkError(message: 'Connection failed'),
        UnknownError(message: 'Something went wrong'),
      ];

      for (final error in errors) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ErrorView(error: error),
            ),
          ),
        );

        expect(find.text(error.message), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      }
    });

    testWidgets('error text is centered', (WidgetTester tester) async {
      final error = BusinessError(message: 'Long error message that should be centered and wrap properly');
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorView(error: error),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text(error.message));
      expect(textWidget.textAlign, TextAlign.center);
    });

    testWidgets('retry button has correct icon and text', (WidgetTester tester) async {
      const error = BusinessError(message: 'Test error');
      bool retryPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            body: ErrorView(
              error: error,
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      // Wait for all animations and rendering
      await tester.pumpAndSettle();

      // Check for retry button text (FilledButton.icon contains text widget)
      final retryTextFinder = find.text('تلاش دوباره');
      expect(retryTextFinder, findsOneWidget);
      
      // Check for refresh icon
      final refreshIconFinder = find.byIcon(Icons.refresh);
      expect(refreshIconFinder, findsOneWidget);
      
      // Test button functionality by tapping on the text
      await tester.tap(retryTextFinder);
      expect(retryPressed, isTrue);
    });
  });
}
