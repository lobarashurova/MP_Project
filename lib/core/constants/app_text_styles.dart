import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Headings
  static TextStyle get heading1 => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading2 => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get heading3 => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  // Body Text
  static TextStyle get bodyLarge => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodySmall => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  // Subtitles
  static TextStyle get subtitle => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  static TextStyle get subtitleSmall => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  // Button Text
  static TextStyle get button => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.surface,
      );

  static TextStyle get buttonPrimary => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      );

  // Product Card
  static TextStyle get productName => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get productPrice => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      );

  static TextStyle get productCategory => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  // Ratings
  static TextStyle get rating => TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get ratingSmall => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: AppColors.textSecondary,
      );

  // Hints
  static TextStyle get hint => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: AppColors.textHint,
      );

  // Banner Text
  static TextStyle get bannerTitle => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.surface,
      );

  static TextStyle get bannerSubtitle => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: AppColors.surface,
      );

  // Navigation
  static TextStyle get navLabel => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      );

  // Categories
  static TextStyle get categoryChip => const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );
}
