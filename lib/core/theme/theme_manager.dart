import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Advanced Theme Manager for handling theme persistence and switching
class ThemeManager extends ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  // Constants
  static const String _themeModeKey = 'theme_mode';
  static const String _customSeedColorKey = 'custom_seed_color';
  static const String _useSystemThemeKey = 'use_system_theme';
  static const String _accessibilityModeKey = 'accessibility_mode';
  static const String _fontScaleKey = 'font_scale';

  // Private properties
  SharedPreferences? _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  Color _customSeedColor = const Color(0xFF0A1992);
  bool _useSystemTheme = true;
  bool _accessibilityMode = false;
  double _fontScale = 1.0;
  bool _isInitialized = false;

  // Getters
  ThemeMode get themeMode => _themeMode;
  Color get customSeedColor => _customSeedColor;
  bool get useSystemTheme => _useSystemTheme;
  bool get accessibilityMode => _accessibilityMode;
  double get fontScale => _fontScale;
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Initialize theme manager
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadThemeSettings();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing ThemeManager: $e');
      _isInitialized = true;
    }
  }

  /// Load theme settings from storage
  Future<void> _loadThemeSettings() async {
    if (_prefs == null) return;

    try {
      // Load theme mode
      final themeModeIndex = _prefs!.getInt(_themeModeKey) ?? ThemeMode.system.index;
      _themeMode = ThemeMode.values[themeModeIndex];

      // Load custom seed color
      final colorValue = _prefs!.getInt(_customSeedColorKey);
      if (colorValue != null) {
        _customSeedColor = Color(colorValue);
      }

      // Load other settings
      _useSystemTheme = _prefs!.getBool(_useSystemThemeKey) ?? true;
      _accessibilityMode = _prefs!.getBool(_accessibilityModeKey) ?? false;
      _fontScale = _prefs!.getDouble(_fontScaleKey) ?? 1.0;

    } catch (e) {
      debugPrint('Error loading theme settings: $e');
    }
  }

  /// Save theme settings to storage
  Future<void> _saveThemeSettings() async {
    if (_prefs == null) return;

    try {
      await _prefs!.setInt(_themeModeKey, _themeMode.index);
      await _prefs!.setInt(_customSeedColorKey, _customSeedColor.value);
      await _prefs!.setBool(_useSystemThemeKey, _useSystemTheme);
      await _prefs!.setBool(_accessibilityModeKey, _accessibilityMode);
      await _prefs!.setDouble(_fontScaleKey, _fontScale);
    } catch (e) {
      debugPrint('Error saving theme settings: $e');
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _saveThemeSettings();
    _updateSystemUI();
    notifyListeners();
  }

  /// Toggle between light and dark themes
  Future<void> toggleTheme() async {
    switch (_themeMode) {
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.system:
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        await setThemeMode(brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
        break;
    }
  }

  /// Set custom seed color for dynamic theming
  Future<void> setCustomSeedColor(Color color) async {
    if (_customSeedColor == color) return;

    _customSeedColor = color;
    await _saveThemeSettings();
    notifyListeners();
  }

  /// Set whether to use system theme
  Future<void> setUseSystemTheme(bool useSystem) async {
    if (_useSystemTheme == useSystem) return;

    _useSystemTheme = useSystem;
    if (useSystem) {
      await setThemeMode(ThemeMode.system);
    }
    await _saveThemeSettings();
    notifyListeners();
  }

  /// Set accessibility mode
  Future<void> setAccessibilityMode(bool enabled) async {
    if (_accessibilityMode == enabled) return;

    _accessibilityMode = enabled;
    await _saveThemeSettings();
    notifyListeners();
  }

  /// Set font scale for accessibility
  Future<void> setFontScale(double scale) async {
    if (_fontScale == scale) return;

    _fontScale = scale.clamp(0.8, 2.0);
    await _saveThemeSettings();
    notifyListeners();
  }

  /// Reset to default theme settings
  Future<void> resetToDefaults() async {
    _themeMode = ThemeMode.system;
    _customSeedColor = const Color(0xFF0A1992);
    _useSystemTheme = true;
    _accessibilityMode = false;
    _fontScale = 1.0;

    await _saveThemeSettings();
    _updateSystemUI();
    notifyListeners();
  }

  /// Update system UI overlay style based on current theme
  void _updateSystemUI() {
    final isDark = _getCurrentBrightness() == Brightness.dark;
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDark ? const Color(0xFF101014) : const Color(0xFFFFFCFF),
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  /// Get current brightness based on theme mode
  Brightness _getCurrentBrightness() {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  /// Generate light theme with current settings
  ThemeData generateLightTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _useSystemTheme ? const Color(0xFF0A1992) : _customSeedColor,
      brightness: Brightness.light,
    );

    return _buildThemeWithSettings(colorScheme, Brightness.light);
  }

  /// Generate dark theme with current settings
  ThemeData generateDarkTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _useSystemTheme ? const Color(0xFF0A1992) : _customSeedColor,
      brightness: Brightness.dark,
    );

    return _buildThemeWithSettings(colorScheme, Brightness.dark);
  }

  /// Build theme with current font scale and accessibility settings
  ThemeData _buildThemeWithSettings(ColorScheme colorScheme, Brightness brightness) {
    // Base theme data would be imported from app_theme.dart
    // This is a simplified version for demonstration
    
    final baseTextTheme = _buildAccessibleTextTheme(colorScheme);
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      textTheme: baseTextTheme,
      
      // Enhanced contrast for accessibility mode
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: _accessibilityMode ? 3 : 1,
          textStyle: TextStyle(
            fontSize: 16 * _fontScale,
            fontWeight: _accessibilityMode ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
      
      // High contrast borders for accessibility
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            width: _accessibilityMode ? 2 : 1,
            color: colorScheme.outline,
          ),
        ),
      ),
    );
  }

  /// Build accessible text theme with font scaling
  TextTheme _buildAccessibleTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 57 * _fontScale,
        fontWeight: _accessibilityMode ? FontWeight.w600 : FontWeight.w400,
        color: colorScheme.onSurface,
        fontFamily: 'IRANSans',
      ),
      headlineLarge: TextStyle(
        fontSize: 32 * _fontScale,
        fontWeight: _accessibilityMode ? FontWeight.w700 : FontWeight.w600,
        color: colorScheme.onSurface,
        fontFamily: 'IRANSans',
      ),
      bodyLarge: TextStyle(
        fontSize: 16 * _fontScale,
        fontWeight: _accessibilityMode ? FontWeight.w500 : FontWeight.w400,
        color: colorScheme.onSurface,
        fontFamily: 'IRANSans',
      ),
      bodyMedium: TextStyle(
        fontSize: 14 * _fontScale,
        fontWeight: _accessibilityMode ? FontWeight.w500 : FontWeight.w400,
        color: colorScheme.onSurface,
        fontFamily: 'IRANSans',
      ),
      labelLarge: TextStyle(
        fontSize: 14 * _fontScale,
        fontWeight: _accessibilityMode ? FontWeight.w700 : FontWeight.w600,
        color: colorScheme.onSurface,
        fontFamily: 'IRANSans',
      ),
    );
  }

  /// Get theme animation duration
  Duration get themeAnimationDuration => const Duration(milliseconds: 300);

  /// Check if device supports dynamic colors (Android 12+)
  bool get supportsDynamicColors {
    // This would typically check the platform and OS version
    // For now, returning false as implementation would require platform channels
    return false;
  }

  /// Export current theme settings
  Map<String, dynamic> exportSettings() {
    return {
      'themeMode': _themeMode.index,
      'customSeedColor': _customSeedColor.value,
      'useSystemTheme': _useSystemTheme,
      'accessibilityMode': _accessibilityMode,
      'fontScale': _fontScale,
    };
  }

  /// Import theme settings
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      if (settings.containsKey('themeMode')) {
        _themeMode = ThemeMode.values[settings['themeMode']];
      }
      if (settings.containsKey('customSeedColor')) {
        _customSeedColor = Color(settings['customSeedColor']);
      }
      if (settings.containsKey('useSystemTheme')) {
        _useSystemTheme = settings['useSystemTheme'];
      }
      if (settings.containsKey('accessibilityMode')) {
        _accessibilityMode = settings['accessibilityMode'];
      }
      if (settings.containsKey('fontScale')) {
        _fontScale = settings['fontScale'];
      }

      await _saveThemeSettings();
      _updateSystemUI();
      notifyListeners();
    } catch (e) {
      debugPrint('Error importing theme settings: $e');
    }
  }
}