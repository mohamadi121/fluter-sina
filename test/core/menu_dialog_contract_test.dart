import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/widgets/appbar/menu_dialog.dart';
import 'package:asood/core/widgets/appbar/profile_menu_widget.dart';

void main() {
  testWidgets('main menu exposes no demo, dead, or disabled routes', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MenuDialog())),
    );

    for (final label in [
      'خانه',
      'پروفایل',
      'رهیابی خرید',
      'اعلان‌ها',
      'پشتیبانی',
      'علاقه‌مندی‌ها',
      'امور مالی',
      'خروج',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('لیست صفحات'), findsNothing);
    expect(find.text('داشبورد فروشنده'), findsNothing);
    expect(find.text('تنظیمات'), findsNothing);
    expect(find.text('درباره ما'), findsNothing);
  });

  testWidgets('profile menu has only implemented actions', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfileMenuDialog())),
    );

    expect(find.text('پروفایل'), findsOneWidget);
    expect(find.text('دعوت دوستان'), findsOneWidget);
    expect(find.text('خروج از حساب کاربری'), findsOneWidget);
    expect(find.text('تماس با ما'), findsNothing);
    expect(find.text('خروج از برنامه'), findsNothing);
  });
}
