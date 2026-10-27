import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

/// The single source of truth for the app's look.
///
/// Screens previously styled every button, card and field by hand, which is
/// why spacing and radii drifted between pages. Defining them once here means
/// an un-styled widget already looks right.
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
  static List<BoxShadow> get cardShadow => const <BoxShadow>[
        BoxShadow(
          color: AppColors.shadowSoft,
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ];

  /// Deeper shadow for surfaces that float above content: nav bar, sheets.
  static List<BoxShadow> get floatingShadow => const <BoxShadow>[
        BoxShadow(
          color: AppColors.shadow,
          blurRadius: 24,
          spreadRadius: -4,
          offset: Offset(0, -2),
        ),
      ];

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      onPrimary: AppColors.surface,
      secondary: AppColors.primaryLight,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTextStyles.heading3,
        iconTheme: const IconThemeData(color: AppColors.iconPrimary),
      ),

      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
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
          foregroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textHint,
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
        fillColor: AppColors.surface,
        hintStyle: AppTextStyles.hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: spaceMd,
          vertical: spaceMd,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: AppColors.border),
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

      // Error messages are the only snackbars left, so default them to a
      // floating, readable treatment instead of the stock black bar.
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.surface,
        ),
        elevation: 4,
        insetPadding: const EdgeInsets.all(spaceMd),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        titleTextStyle: AppTextStyles.heading3,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        showDragHandle: true,
        dragHandleColor: AppColors.border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLarge),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceAlt,
        selectedColor: AppColors.primary,
        side: BorderSide.none,
        labelStyle: AppTextStyles.categoryChip,
        padding: const EdgeInsets.symmetric(
          horizontal: spaceSm,
          vertical: spaceSm,
        ),
        shape: const StadiumBorder(),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),

      iconTheme: const IconThemeData(color: AppColors.iconPrimary),
    );
  }
}
