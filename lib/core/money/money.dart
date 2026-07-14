/// Parses a whole-IRT API value without passing through binary floating point.
int parseWholeMoney(dynamic value) {
  if (value is int) return value;
  final raw = value?.toString().trim() ?? '';
  if (!RegExp(r'^-?\d+(?:\.0+)?$').hasMatch(raw)) {
    throw const FormatException('Money value must be whole IRT');
  }
  return int.parse(raw.split('.').first);
}

String encodeWholeMoney(int value) => value.toString();
