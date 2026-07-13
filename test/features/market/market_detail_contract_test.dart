import 'package:flutter_test/flutter_test.dart';

import 'package:asood/features/market/presentation/screens/market_preview_screen.dart';
import 'package:asood/features/market/presentation/screens/store_detail_screen.dart';
import 'package:asood/features/market/presentation/widgets/share_store.dart';

void main() {
  test('market detail screens expose only server-backed sections', () {
    expect(publicMarketDetailTabs, ['محصولات', 'نظرات']);
    expect(ownerMarketDetailTabs, ['محصولات', 'نظرات']);
    expect(publicMarketDetailTabs, isNot(contains('ویژه ها')));
    expect(publicMarketDetailTabs, isNot(contains('ارتباط با ما')));
    expect(ownerMarketDetailTabs, isNot(contains('ویژه ها')));
    expect(ownerMarketDetailTabs, isNot(contains('ارتباط با ما')));
  });

  test('store sharing builds only canonical secure storefront URLs', () {
    expect(
      ShareStore.buildUri('My-Shop').toString(),
      'https://my-shop.asoud.ir/',
    );
    expect(ShareStore.buildUri(''), isNull);
    expect(ShareStore.buildUri('null'), isNull);
    expect(ShareStore.buildUri('bad host'), isNull);
    expect(ShareStore.buildUri('shop.example.com'), isNull);
    expect(ShareStore.buildUri('-shop'), isNull);
    expect(ShareStore.buildUri('shop-'), isNull);
    expect(ShareStore.buildUri('aaaaaaaaaaaaaaaaaaaaa'), isNull);
  });
}
