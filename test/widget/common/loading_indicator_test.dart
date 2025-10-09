import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Loading indicator should display', (tester) async {
    // Build widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
    
    // Verify
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
