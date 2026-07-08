import 'package:flutter/foundation.dart';

import 'package:asood/core/logging/app_logger.dart';

import 'token_storage.dart';

/// Single owner of the auth token at runtime.
///
/// Everything auth-related goes through here: DioClient reads the token,
/// AuthBloc sets/clears it, GoRouter listens for changes to redirect.
/// Nothing else may touch token storage directly.
class AuthSession extends ChangeNotifier {
  final TokenStorage _storage;

  String? _token;
  bool _hydrated = false;

  AuthSession(this._storage);

  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isHydrated => _hydrated;

  /// Loads the persisted token once at startup.
  Future<void> hydrate() async {
    _token = await _storage.read();
    _hydrated = true;
    AppLogger.info(
      'auth',
      'session hydrated: ${isAuthenticated ? 'authenticated' : 'anonymous'}',
    );
    notifyListeners();
  }

  Future<void> setToken(String token) async {
    await _storage.write(token);
    _token = token;
    notifyListeners();
  }

  /// Logs out locally. Also invoked when the backend answers 401,
  /// which means the token was revoked server-side.
  Future<void> clear() async {
    if (_token == null) {
      return;
    }
    await _storage.clear();
    _token = null;
    AppLogger.info('auth', 'session cleared');
    notifyListeners();
  }
}
