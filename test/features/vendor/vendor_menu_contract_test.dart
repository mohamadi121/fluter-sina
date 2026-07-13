import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/router/app_routers.dart';
import 'package:asood/features/vendor/presentation/screen/vendor_home.dart';

void main() {
  test('vendor dashboard exposes only supported destinations', () {
    final first = dashboardMenuConfig['firstMenu']!;
    final second = dashboardMenuConfig['secondMenu']!;

    expect(first.map((item) => item['title']), ['میز کار', 'استعلام بها']);
    expect(second.map((item) => item['title']), [
      'امور مالی',
      'رهیابی خرید',
      'اشتراک گذاری',
      'علاقه مندی',
    ]);
    expect(
      second.where((item) => item['page'] == null).single['title'],
      'اشتراک گذاری',
    );
    expect(first.map((item) => item['page']), [
      AppRoutes.createWorkSpace,
      AppRoutes.inquiryRequests,
    ]);
    expect(second.map((item) => item['page']), [
      AppRoutes.finance,
      AppRoutes.customerDashboard,
      null,
      AppRoutes.bookmarks,
    ]);
    expect(() => first.add({'title': 'unsupported'}), throwsUnsupportedError);
    expect(() => first.first['page'] = '/unsupported', throwsUnsupportedError);
  });
}
