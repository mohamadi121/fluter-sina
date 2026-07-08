import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persistence boundary for the auth token, so session logic stays
/// platform-independent and testable.
abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  static const _key = 'token';

  final FlutterSecureStorage _storage;

  const SecureTokenStorage([this._storage = const FlutterSecureStorage()]);

  @override
  Future<String?> read() async {
    final value = await _storage.read(key: _key);
    // 'ND' is the legacy "no data" sentinel written by the old storage
    // helper; installs upgraded from it must read as logged-out.
    if (value == null || value == 'ND') {
      return null;
    }
    return value;
  }

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
