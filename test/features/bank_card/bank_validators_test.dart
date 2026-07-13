import 'package:flutter_test/flutter_test.dart';

import 'package:asood/features/bank_card/domain/bank_validators.dart';

void main() {
  test('bank card validator enforces format and checksum', () {
    expect(isValidBankCardNumber('6037997512345670'), isTrue);
    expect(isValidBankCardNumber('6037997512345678'), isFalse);
    expect(isValidBankCardNumber('0000000000000000'), isFalse);
    expect(isValidBankCardNumber('۱۲۳۴۵۶۷۸۹۰۱۲۳۴۵۶'), isFalse);
  });

  test('Iranian IBAN validator enforces format and ISO checksum', () {
    expect(isValidIranianIban('IR641234567890123456789012'), isTrue);
    expect(isValidIranianIban('IR123456789012345678901234'), isFalse);
    expect(isValidIranianIban('641234567890123456789012'), isFalse);
  });
}
