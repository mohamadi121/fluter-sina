import 'package:asood/core/auth/token_storage.dart';

class InMemoryTokenStorage implements TokenStorage {
  String? value;

  InMemoryTokenStorage([this.value]);

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String token) async => value = token;

  @override
  Future<void> clear() async => value = null;
}
