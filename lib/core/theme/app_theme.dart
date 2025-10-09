import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Advanced Theme System for Material Design 3
/// Supports dynamic colors, dark/light modes, and accessibility
class AppTheme {
  AppTheme._();

  // Color schemes based on Material Design 3
  static const _primarySeedColor = Color(0xFF0A1992); // Smart Home primary
  static const _secondarySeedColor = Color(0xFF2537C5); // Smart Home secondary

  // Static color references for compatibility
  static Color get primaryColor => _primarySeedColor;
  static Color get secondaryColor => _secondarySeedColor;

  // Typography
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.33,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  /// Light Theme Data
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primarySeedColor,
      brightness: Brightness.light,
    ).copyWith(
      secondary: _secondarySeedColor,
      tertiary: const Color(0xFF405AEB),
      surface: const Color(0xFFFFFCFF),
      onSurface: const Color(0xFF1C1B1F),
      surfaceVariant: const Color(0xFFE7E0EC),
      outline: const Color(0xFF79747E),
    );

    return _buildTheme(colorScheme, Brightness.light);
  }

  /// Dark Theme Data
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primarySeedColor,
      brightness: Brightness.dark,
    ).copyWith(
      secondary: _secondarySeedColor,
      tertiary: const Color(0xFF5264F0),
      surface: const Color(0xFF101014),
      onSurface: const Color(0xFFE6E1E5),
      surfaceVariant: const Color(0xFF49454F),
      outline: const Color(0xFF938F99),
    );

    return _buildTheme(colorScheme, Brightness.dark);
  }

  /// Build theme with common properties
  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      
      // Typography
      textTheme: _buildTextTheme(colorScheme),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          fontFamily: 'IRANSans',
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),

      // Scaffold Theme
      scaffoldBackgroundColor: colorScheme.surface,

      // Card Theme
      cardTheme: CardTheme(
        elevation: 1,
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 1,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'IRANSans',
          ),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'IRANSans',
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'IRANSans',
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontFamily: 'IRANSans',
        ),
        hintStyle: TextStyle(
          color: colorScheme.onSurfaceVariant.withOpacity(0.6),
          fontFamily: 'IRANSans',
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        elevation: 3,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'IRANSans',
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          fontFamily: 'IRANSans',
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 3,
        focusElevation: 4,
        hoverElevation: 4,
        highlightElevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
          fontFamily: 'IRANSans',
        ),
        contentTextStyle: TextStyle(
          fontSize: 16,
          color: colorScheme.onSurfaceVariant,
          fontFamily: 'IRANSans',
        ),
      ),

      // Snack Bar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: colorScheme.onInverseSurface,
          fontFamily: 'IRANSans',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 3,
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        selectedColor: colorScheme.secondaryContainer,
        disabledColor: colorScheme.onSurface.withOpacity(0.12),
        labelStyle: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontFamily: 'IRANSans',
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 1,
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceVariant,
        circularTrackColor: colorScheme.surfaceVariant,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withOpacity(0.2),
        thickness: 1,
        space: 1,
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: 24,
      ),

      // Primary Icon Theme
      primaryIconTheme: IconThemeData(
        color: colorScheme.onPrimary,
        size: 24,
      ),
    );
  }

  /// Build text theme with custom fonts
  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      // Display styles
      displayLarge: TextStyle(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.25,
        color: colorScheme.onSurface,
        fontFamily: 'IRANSans',
      ),
      displayMedium: TextStyle(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        fontFamily: 'IRANSans',
      ),
      displaySmall: TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        fontFamily: 'IRANSans',
      ),

      // Headline styles
      headlineLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        fontFamily: 'IRANSans',
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        fontFamily: 'IRANSans',
      ),
      headlineSmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        fontFamily: 'IRANSans',
      ),

      // Title styles
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: colorScheme.onSurface,
        fontFamily: 'IRANSans',
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: colorScheme.onSurface,
        fontFamily: 'IRANSans',
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        fontFamily: 'IRANSans',
      ),

      // Body styles
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        fontFamily: 'IRANSans',
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: colorScheme.onSurface,
        fontFamily: 'IRANSans',
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: colorScheme.onSurfaceVariant,
        fontFamily: 'IRANSans',
      ),

      // Label styles
      labelLarge: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: colorScheme.onSurface,
        fontFamily: 'IRANSans',
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colorScheme.onSurface,
        fontFamily: 'IRANSans',
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: colorScheme.onSurfaceVariant,
        fontFamily: 'IRANSans',
      ),
    );
  }
}

/// Theme extensions for custom properties
extension AppThemeExtension on ThemeData {
  /// Custom spacing values
  double get spacingXS => 4.0;
  double get spacingS => 8.0;
  double get spacingM => 16.0;
  double get spacingL => 24.0;
  double get spacingXL => 32.0;
  double get spacingXXL => 48.0;

  /// Custom border radius values
  double get radiusS => 8.0;
  double get radiusM => 16.0;
  double get radiusL => 24.0;
  double get radiusXL => 32.0;

  /// Custom elevation values
  double get elevationS => 1.0;
  double get elevationM => 3.0;
  double get elevationL => 6.0;
  double get elevationXL => 12.0;

  /// Custom opacity values
  double get opacityDisabled => 0.38;
  double get opacityHover => 0.08;
  double get opacityFocus => 0.12;
  double get opacityPressed => 0.16;
}

/// Custom theme colors for specific use cases
extension CustomColorScheme on ColorScheme {
  /// Success colors
  Color get success => const Color(0xFF4CAF50);
  Color get onSuccess => const Color(0xFFFFFFFF);
  Color get successContainer => const Color(0xFFE8F5E8);
  Color get onSuccessContainer => const Color(0xFF1B5E20);

  /// Warning colors
  Color get warning => const Color(0xFFFF9800);
  Color get onWarning => const Color(0xFF000000);
  Color get warningContainer => const Color(0xFFFFF3E0);
  Color get onWarningContainer => const Color(0xFFE65100);

  /// Info colors
  Color get info => const Color(0xFF2196F3);
  Color get onInfo => const Color(0xFFFFFFFF);
  Color get infoContainer => const Color(0xFFE3F2FD);
  Color get onInfoContainer => const Color(0xFF0D47A1);

  /// Asoud brand specific colors
  Color get asoudPrimary => const Color(0xFF0A1992);
  Color get asoudSecondary => const Color(0xFF2537C5);
  Color get asoudTertiary => const Color(0xFF405AEB);
  Color get asoudNeutral => const Color(0xFF79747E);
}