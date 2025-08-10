import 'package:flutter/material.dart';

/// Design color tokens (single source of truth)
class AppColorTokens {
  AppColorTokens._();

  // Seed & Brand
  static const Color seed = Color(0xFF1D4ED8); // Indigo 600
  static const Color brandPrimary = seed;
  static const Color brandSecondary = Color(0xFF6366F1); // Indigo 400

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF0EA5E9);

  // Neutral palette (Material 3 style steps)
  static const Color neutral0 = Color(0xFFFFFFFF);
  static const Color neutral10 = Color(0xFFF5F7FA);
  static const Color neutral20 = Color(0xFFE7EAF0);
  static const Color neutral30 = Color(0xFFD0D5DD);
  static const Color neutral40 = Color(0xFF98A2B3);
  static const Color neutral50 = Color(0xFF667085);
  static const Color neutral60 = Color(0xFF475467);
  static const Color neutral70 = Color(0xFF344054);
  static const Color neutral80 = Color(0xFF1D2939);
  static const Color neutral90 = Color(0xFF0C111D);

  // Elevation overlays (for dark mode tweak)
  static Color surfaceTint(ColorScheme scheme) => scheme.primary;
}
