import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asood/features/analytics/screens/analytics_dashboard_screen.dart';

void main() {
  testWidgets('gross revenue disclaimer is explicitly visible', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GrossRevenueDisclaimer(refundsDeducted: false)),
      ),
    );

    expect(
      find.byKey(const Key('gross-revenue-refund-disclaimer')),
      findsOneWidget,
    );
    expect(find.textContaining('بازپرداخت‌شده از آن کسر نشده'), findsOneWidget);
  });

  testWidgets('disclaimer is hidden only when refunds were deducted', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: GrossRevenueDisclaimer(refundsDeducted: true)),
      ),
    );

    expect(
      find.byKey(const Key('gross-revenue-refund-disclaimer')),
      findsNothing,
    );
  });
}
