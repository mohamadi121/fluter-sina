import 'package:flutter_test/flutter_test.dart';

import 'package:asood/features/market/data/model/product_model.dart';
import 'package:asood/features/market/presentation/blocs/add_product/add_product_bloc.dart';

void main() {
  test('product editor exposes no customer-paid shipping mode', () {
    expect(SendPriceEnum.values, [SendPriceEnum.market, SendPriceEnum.free]);
  });

  test('product payload has no standalone hardcoded shipping cost', () {
    final payload =
        ProductModel(
          market: 'm1',
          type: 'good',
          name: 'p1',
          shipCostPayType: SendPriceEnum.free.name,
        ).toJson();

    expect(payload.containsKey('ship_cost'), isFalse);
    expect(payload['ship_cost_pay_type'], 'free');
  });
}
