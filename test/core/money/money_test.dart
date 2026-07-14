import 'package:flutter_test/flutter_test.dart';

import 'package:asood/core/money/money.dart';
import 'package:asood/features/payment/domain/models/payment_model.dart';
import 'package:asood/features/wallet/domain/models/wallet_model.dart';

void main() {
  test('whole money parses numeric and canonical string responses exactly', () {
    expect(parseWholeMoney(9007199254740991), 9007199254740991);
    expect(parseWholeMoney('9007199254740991'), 9007199254740991);
    expect(parseWholeMoney('1500.000'), 1500);
  });

  test('fractional money is rejected instead of rounded', () {
    expect(() => parseWholeMoney('1.001'), throwsFormatException);
    expect(() => parseWholeMoney(1.5), throwsFormatException);
  });

  test('payment and wallet models accept backend Decimal strings', () {
    final payment = PaymentModel.fromJson({
      'id': 'payment-1',
      'amount': '1500',
      'status': 'pending',
      'created_at': '2026-07-13T00:00:00Z',
    });
    final wallet = WalletModel.fromJson({'id': 'wallet-1', 'balance': '2500'});
    final transaction = TransactionModel.fromJson({
      'id': 'transaction-1',
      'action': 'charge',
      'amount': '1000',
      'created_at': '2026-07-13T00:00:00Z',
    });

    expect(payment.amount, 1500);
    expect(payment.toJson()['amount'], '1500');
    expect(wallet.balance, 2500);
    expect(wallet.toJson()['balance'], '2500');
    expect(transaction.type, 'charge');
    expect(transaction.toJson()['amount'], '1000');
  });
}
