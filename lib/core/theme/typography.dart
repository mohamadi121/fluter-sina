import 'package:flutter/material.dart';

/// Typography scale (can adapt dynamic font families)
class AppTypography {
  AppTypography._();

  static const String primaryFont = 'irs';

  static TextTheme textTheme(ColorScheme scheme) => TextTheme(
        displayLarge: TextStyle(fontFamily: primaryFont, fontSize: 32, fontWeight: FontWeight.w700, color: scheme.onSurface),
        displayMedium: TextStyle(fontFamily: primaryFont, fontSize: 28, fontWeight: FontWeight.w600, color: scheme.onSurface),
        displaySmall: TextStyle(fontFamily: primaryFont, fontSize: 24, fontWeight: FontWeight.w600, color: scheme.onSurface),
        headlineLarge: TextStyle(fontFamily: primaryFont, fontSize: 22, fontWeight: FontWeight.w600, color: scheme.onSurface),
        headlineMedium: TextStyle(fontFamily: primaryFont, fontSize: 20, fontWeight: FontWeight.w500, color: scheme.onSurface),
        headlineSmall: TextStyle(fontFamily: primaryFont, fontSize: 18, fontWeight: FontWeight.w500, color: scheme.onSurface),
        titleLarge: TextStyle(fontFamily: primaryFont, fontSize: 16, fontWeight: FontWeight.w600, color: scheme.onSurface),
        titleMedium: TextStyle(fontFamily: primaryFont, fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface),
        titleSmall: TextStyle(fontFamily: primaryFont, fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
        bodyLarge: TextStyle(fontFamily: primaryFont, fontSize: 16, fontWeight: FontWeight.w400, height: 1.4, color: scheme.onSurface),
        bodyMedium: TextStyle(fontFamily: primaryFont, fontSize: 14, fontWeight: FontWeight.w400, height: 1.4, color: scheme.onSurface),
        bodySmall: TextStyle(fontFamily: primaryFont, fontSize: 12, fontWeight: FontWeight.w400, height: 1.4, color: scheme.onSurfaceVariant),
        labelLarge: TextStyle(fontFamily: primaryFont, fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onPrimary),
        labelMedium: TextStyle(fontFamily: primaryFont, fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onPrimaryContainer),
        labelSmall: TextStyle(fontFamily: primaryFont, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: .5, color: scheme.onSurfaceVariant),
      );
}
