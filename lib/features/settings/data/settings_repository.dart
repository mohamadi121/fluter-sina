import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _kThemeMode = 'theme_mode'; // system / light / dark
  static const _kLocale = 'locale'; // fa / en
  static const _kEnvironment = 'environment'; // dev / prod

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> saveThemeMode(String mode) async {
    final p = await _prefs; await p.setString(_kThemeMode, mode);
  }
  Future<String?> loadThemeMode() async { final p = await _prefs; return p.getString(_kThemeMode); }

  Future<void> saveLocale(String locale) async { final p = await _prefs; await p.setString(_kLocale, locale); }
  Future<String?> loadLocale() async { final p = await _prefs; return p.getString(_kLocale); }

  Future<void> saveEnvironment(String env) async { final p = await _prefs; await p.setString(_kEnvironment, env); }
  Future<String?> loadEnvironment() async { final p = await _prefs; return p.getString(_kEnvironment); }
}
