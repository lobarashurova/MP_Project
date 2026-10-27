import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFFE65E07);
  static const Color primaryLight = Color(0xFFFF8A3D);
  static const Color primaryDark = Color(0xFFB34805);

  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textHint = Color(0xFF9E9E9E);

  // Accent Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // Border & Divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // Icon Colors
  static const Color iconPrimary = Color(0xFF424242);
  static const Color iconSecondary = Color(0xFF9E9E9E);

  // Shadow — three depths so elevation reads as a scale, not one flat blur.
  static const Color shadow = Color(0x1A000000);
  static const Color shadowSoft = Color(0x0D000000);
  static const Color shadowStrong = Color(0x26000000);

  // Tinted surfaces built from the brand colour. Pre-mixed against white so
  // they stay opaque and avoid the muddy edges you get from stacked alphas.
  static const Color primarySoft = Color(0xFFFDF0E7);
  static const Color primaryTint = Color(0xFFFBE2D2);
  static const Color surfaceAlt = Color(0xFFF4F4F6);

  /// Warm brand gradient for banners and primary calls to action.
  static const List<Color> primaryGradient = <Color>[
    Color(0xFFFF8A3D),
    Color(0xFFE65E07),
  ];
}
