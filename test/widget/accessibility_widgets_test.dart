import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asoud/core/widgets/accessibility_widgets.dart';

void main() {
  group('Accessibility Widgets Tests', () {
    testWidgets('AccessibleButton shows label and responds to tap', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleButton(
              label: 'Test Button',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      // Find the button
      expect(find.text('Test Button'), findsOneWidget);
      
      // Tap the button
      await tester.tap(find.text('Test Button'));
      expect(tapped, isTrue);
    });

    testWidgets('AccessibleTextField shows label and accepts input', (tester) async {
      final controller = TextEditingController();
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleTextField(
              label: 'Test Field',
              controller: controller,
            ),
          ),
        ),
      );

      // Find the text field
      expect(find.byType(TextFormField), findsOneWidget);
      
      // Enter text
      await tester.enterText(find.byType(TextFormField), 'Test input');
      expect(controller.text, equals('Test input'));
    });

    testWidgets('AccessibleLoadingIndicator shows loading message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleLoadingIndicator(
              message: 'Loading test data...',
            ),
          ),
        ),
      );

      expect(find.text('Loading test data...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('AccessibleEmptyState shows title and action', (tester) async {
      bool actionTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleEmptyState(
              title: 'No data found',
              subtitle: 'Try refreshing the page',
              actionLabel: 'Refresh',
              onAction: () => actionTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('No data found'), findsOneWidget);
      expect(find.text('Try refreshing the page'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);
      
      await tester.tap(find.text('Refresh'));
      expect(actionTapped, isTrue);
    });

    testWidgets('AccessibleErrorState shows error and retry action', (tester) async {
      bool retryTapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleErrorState(
              title: 'Something went wrong',
              subtitle: 'Please try again',
              actionLabel: 'Retry',
              onRetry: () => retryTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Please try again'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      
      await tester.tap(find.text('Retry'));
      expect(retryTapped, isTrue);
    });
  });
}
