import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:asood/core/auth/auth_session.dart';
import 'package:asood/core/router/app_routers.dart';
import 'package:asood/locator.dart';

class MenuDialog extends StatelessWidget {
  const MenuDialog({super.key});

  void _open(BuildContext context, String route) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push(route);
  }

  Future<void> _logout(BuildContext context) async {
    Navigator.of(context).pop();
    await locator<AuthSession>().clear();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('منو'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MenuItem(
              title: 'خانه',
              onTap: () => _open(context, AppRoutes.vendorHome),
            ),
            _MenuItem(
              title: 'پروفایل',
              onTap: () => _open(context, AppRoutes.vendorProfile),
            ),
            _MenuItem(
              title: 'رهیابی خرید',
              onTap: () => _open(context, AppRoutes.customerDashboard),
            ),
            _MenuItem(
              title: 'اعلان‌ها',
              onTap: () => _open(context, AppRoutes.notifications),
            ),
            _MenuItem(
              title: 'پشتیبانی',
              onTap: () => _open(context, AppRoutes.support),
            ),
            _MenuItem(
              title: 'علاقه‌مندی‌ها',
              onTap: () => _open(context, AppRoutes.bookmarks),
            ),
            _MenuItem(
              title: 'امور مالی',
              onTap: () => _open(context, AppRoutes.finance),
            ),
            _MenuItem(title: 'خروج', onTap: () => _logout(context)),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _MenuItem({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(title), onTap: onTap);
  }
}
