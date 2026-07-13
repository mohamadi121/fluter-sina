bool isValidBankCardNumber(String value) {
  if (!RegExp(r'^\d{16}$').hasMatch(value)) return false;
  if (value.substring(0, 8) == '00000000') return false;
  var total = 0;
  for (var index = 0; index < value.length; index++) {
    final digit = int.parse(value[index]);
    final weighted = digit * (index.isEven ? 2 : 1);
    total += weighted > 9 ? weighted - 9 : weighted;
  }
  return total % 10 == 0;
}

bool isValidIranianIban(String value) {
  if (!RegExp(r'^IR\d{24}$').hasMatch(value)) return false;
  final numeric = '${value.substring(4)}1827${value.substring(2, 4)}';
  return BigInt.parse(numeric) % BigInt.from(97) == BigInt.one;
}
