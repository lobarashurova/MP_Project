import 'package:flutter/material.dart';

/// The app's colour tokens.
///
/// Every colour exists as a `light*`/`dark*` pair, and the plain name is a
/// getter that picks one based on [isDarkMode]. Screens therefore write
/// `AppColors.background` and get the right value in either theme.
///
/// [isDarkMode] is written only by ThemeProvider, which sets it before the
/// first frame and on every toggle.
class AppColors {
  AppColors._();

  static bool isDarkMode = false;

  // ---------------------------------------------------------------- brand
  // The brand orange is the same in both themes; it is the one fixed point
  // the rest of the palette is balanced against.
  static const Color primary = Color(0xFFE65E07);
  static const Color primaryLight = Color(0xFFFF8A3D);
  static const Color primaryDark = Color(0xFFB34805);

  /// Warm brand gradient for banners and primary calls to action.
  static const List<Color> primaryGradient = <Color>[
    Color(0xFFFF8A3D),
    Color(0xFFE65E07),
  ];

  // ----------------------------------------------------------- light mode
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

  // Three shadow depths so elevation reads as a scale, not one flat blur.
  static const Color lightShadow = Color(0x1A000000);
  static const Color lightShadowSoft = Color(0x0D000000);
  static const Color lightShadowStrong = Color(0x26000000);

  // Tinted surfaces built from the brand colour, pre-mixed against the
  // background so they stay opaque and avoid the muddy edges you get from
  // stacking alphas.
  static const Color lightPrimarySoft = Color(0xFFFDF0E7);
  static const Color lightPrimaryTint = Color(0xFFFBE2D2);
  static const Color lightSurfaceAlt = Color(0xFFF4F4F6);

  // ------------------------------------------------------------ dark mode
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

  // Shadows go heavier in the dark theme: against a near-black background a
  // light blur is invisible, so depth has to come from a darker spread.
  static const Color darkShadow = Color(0x40000000);
  static const Color darkShadowSoft = Color(0x26000000);
  static const Color darkShadowStrong = Color(0x66000000);

  // The dark tints are mixed towards the brand hue from the dark surface,
  // not from white, so they read as warm panels rather than grey haze.
  static const Color darkPrimarySoft = Color(0xFF2A1D14);
  static const Color darkPrimaryTint = Color(0xFF3A2719);
  static const Color darkSurfaceAlt = Color(0xFF2A2A2E);

  // ------------------------------------------------------ status (shared)
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFF44336);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);

  // -------------------------------------------------------------- getters
  static Color get background => isDarkMode ? darkBackground : lightBackground;
  static Color get surface => isDarkMode ? darkSurface : lightSurface;
  static Color get cardBackground =>
      isDarkMode ? darkCardBackground : lightCardBackground;

  static Color get textPrimary =>
      isDarkMode ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary =>
      isDarkMode ? darkTextSecondary : lightTextSecondary;
  static Color get textHint => isDarkMode ? darkTextHint : lightTextHint;

  static Color get border => isDarkMode ? darkBorder : lightBorder;
  static Color get divider => isDarkMode ? darkDivider : lightDivider;

  static Color get iconPrimary =>
      isDarkMode ? darkIconPrimary : lightIconPrimary;
  static Color get iconSecondary =>
      isDarkMode ? darkIconSecondary : lightIconSecondary;

  static Color get shadow => isDarkMode ? darkShadow : lightShadow;
  static Color get shadowSoft => isDarkMode ? darkShadowSoft : lightShadowSoft;
  static Color get shadowStrong =>
      isDarkMode ? darkShadowStrong : lightShadowStrong;

  static Color get primarySoft =>
      isDarkMode ? darkPrimarySoft : lightPrimarySoft;
  static Color get primaryTint =>
      isDarkMode ? darkPrimaryTint : lightPrimaryTint;
  static Color get surfaceAlt => isDarkMode ? darkSurfaceAlt : lightSurfaceAlt;

  /// Text and icons drawn on top of the brand orange. White in both themes —
  /// the orange never changes, so neither should what sits on it.
  static const Color onPrimary = Color(0xFFFFFFFF);
}
