import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static bool isDarkMode = false;

  // Primary Colors
  static const Color primary = Color(0xFFE65E07);
  static const Color primaryLight = Color(0xFFFF8A3D);
  static const Color primaryDark = Color(0xFFB34805);

  // Light Mode Colors
  static const Color lightBackground = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardBackground = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF6B6B6B);
  static const Color lightTextHint = Color(0xFF9E9E9E);
  static const Color lightBorder = Color(0xFFE0E0E0);
  static const Color lightDivider = Color(0xFFEEEEEE);
  static const Color lightIconPrimary = Color(0xFF424242);
  static const Color lightIconSecondary = Color(0xFF9E9E9E);
  static const Color lightShadow = Color(0x1A000000);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCardBackground = Color(0xFF242424);
  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFA0A0A0);
  static const Color darkTextHint = Color(0xFF757575);
  static const Color darkBorder = Color(0xFF2C2C2C);
  static const Color darkDivider = Color(0xFF2C2C2C);
  static const Color darkIconPrimary = Color(0xFFE0E0E0);
  static const Color darkIconSecondary = Color(0xFF9E9E9E);
  static const Color darkShadow = Color(0x40000000);

  // Dynamic Background Colors
  static Color get background => isDarkMode ? darkBackground : lightBackground;
  static Color get surface => isDarkMode ? darkSurface : lightSurface;
  static Color get cardBackground => isDarkMode ? darkCardBackground : lightCardBackground;

  // Dynamic Text Colors
  static Color get textPrimary => isDarkMode ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary => isDarkMode ? darkTextSecondary : lightTextSecondary;
  static Color get textHint => isDarkMode ? darkTextHint : lightTextHint;

  // Accent Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // Dynamic Border & Divider
  static Color get border => isDarkMode ? darkBorder : lightBorder;
  static Color get divider => isDarkMode ? darkDivider : lightDivider;

  // Dynamic Icon Colors
  static Color get iconPrimary => isDarkMode ? darkIconPrimary : lightIconPrimary;
  static Color get iconSecondary => isDarkMode ? darkIconSecondary : lightIconSecondary;

  // Dynamic Shadow
  static Color get shadow => isDarkMode ? darkShadow : lightShadow;
}
