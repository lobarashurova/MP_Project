import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// The single source of truth for the app's look.
///
/// Screens used to style every button, card and field by hand, which is why
/// spacing and radii drifted between pages. Defining them once here means an
/// un-styled widget already looks right, in either theme.
class AppTheme {
  AppTheme._();

  /// Corner radii, as a scale rather than ad-hoc numbers.
  static const double radiusSmall = 10;
  static const double radiusMedium = 14;
  static const double radiusLarge = 20;
  static const double radiusPill = 999;

  /// Spacing scale, in logical pixels.
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  /// Soft, close shadow for resting cards.
  static List<BoxShadow> get cardShadow => <BoxShadow>[
        BoxShadow(
          color: AppColors.shadowSoft,
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  /// Deeper shadow for surfaces that float above content: nav bar, sheets.
  static List<BoxShadow> get floatingShadow => <BoxShadow>[
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 24,
          spreadRadius: -4,
          offset: const Offset(0, -2),
        ),
      ];

  /// Shadow for something lifted deliberately: a pressed card, a sheet.
  static List<BoxShadow> get raisedShadow => <BoxShadow>[
        BoxShadow(
          color: AppColors.shadowStrong,
          blurRadius: 28,
          spreadRadius: -6,
          offset: const Offset(0, 10),
        ),
      ];

  static ThemeData get lightTheme => _build(Brightness.light);

  static ThemeData get darkTheme => _build(Brightness.dark);

  /// Both themes come out of one builder so a component styled for light mode
  /// cannot quietly fall back to Material defaults in dark mode.
  ///
  /// The colours are read from the `AppColors` getters, which means
  /// [AppColors.isDarkMode] must already match [brightness] when this runs.
  /// ThemeProvider guarantees that: it sets the flag before notifying, and
  /// MaterialApp rebuilds both themes on the next frame.
  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final surface = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final background =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final card =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textHint = isDark ? AppColors.darkTextHint : AppColors.lightTextHint;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final divider = isDark ? AppColors.darkDivider : AppColors.lightDivider;
    final iconPrimary =
        isDark ? AppColors.darkIconPrimary : AppColors.lightIconPrimary;
    final surfaceAlt =
        isDark ? AppColors.darkSurfaceAlt : AppColors.lightSurfaceAlt;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: AppColors.primaryLight,
      onSecondary: AppColors.onPrimary,
      surface: surface,
      onSurface: textPrimary,
      error: AppColors.error,
      onError: AppColors.onPrimary,
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: card,
      dividerColor: divider,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.heading3.copyWith(color: textPrimary),
        iconTheme: IconThemeData(color: iconPrimary),
      ),

      cardTheme: CardThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: border,
          disabledForegroundColor: textHint,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: spaceLg),
          textStyle: AppTextStyles.button.copyWith(fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: spaceLg),
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: AppTextStyles.button.copyWith(
            fontSize: 16,
            color: AppColors.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMedium),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSmall),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfaceAlt : surface,
        hintStyle: AppTextStyles.hint.copyWith(color: textHint),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        titleTextStyle: AppTextStyles.heading3.copyWith(color: textPrimary),
        contentTextStyle:
            AppTextStyles.bodyMedium.copyWith(color: textSecondary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLarge),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: surfaceAlt,
        selectedColor: AppColors.primary,
        side: BorderSide.none,
        labelStyle: AppTextStyles.categoryChip.copyWith(color: textPrimary),
        secondaryLabelStyle:
            AppTextStyles.categoryChip.copyWith(color: AppColors.onPrimary),
        padding: const EdgeInsets.symmetric(
          horizontal: spaceSm,
          vertical: spaceSm,
        ),
        shape: const StadiumBorder(),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.onPrimary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return null;
        }),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: iconPrimary,
        textColor: textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: divider,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

      iconTheme: IconThemeData(color: iconPrimary),

      textTheme: TextTheme(
        headlineLarge: AppTextStyles.heading1.copyWith(color: textPrimary),
        headlineMedium: AppTextStyles.heading2.copyWith(color: textPrimary),
        headlineSmall: AppTextStyles.heading3.copyWith(color: textPrimary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: textPrimary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: textPrimary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: textSecondary),
      ),
    );
  }
}
