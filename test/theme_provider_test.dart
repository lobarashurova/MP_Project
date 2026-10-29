import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xurmo/core/constants/app_colors.dart';
import 'package:xurmo/core/theme/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeProvider', () {
    test('initializes with default light mode when no preference stored', () {
      final provider = ThemeProvider(initialIsDarkMode: false);

      expect(provider.isDarkMode, isFalse);
      expect(provider.themeMode, ThemeMode.light);
      expect(AppColors.isDarkMode, isFalse);
      expect(AppColors.background, AppColors.lightBackground);
    });

    test('initializes with dark mode when initialIsDarkMode is true', () {
      final provider = ThemeProvider(initialIsDarkMode: true);

      expect(provider.isDarkMode, isTrue);
      expect(provider.themeMode, ThemeMode.dark);
      expect(AppColors.isDarkMode, isTrue);
      expect(AppColors.background, AppColors.darkBackground);
    });

    test('toggleTheme switches mode, notifies listeners and saves to SharedPreferences', () async {
      final provider = ThemeProvider(initialIsDarkMode: false);
      var notifiedCount = 0;
      provider.addListener(() {
        notifiedCount++;
      });

      await provider.toggleTheme(true);

      expect(provider.isDarkMode, isTrue);
      expect(provider.themeMode, ThemeMode.dark);
      expect(AppColors.isDarkMode, isTrue);
      expect(AppColors.background, AppColors.darkBackground);
      expect(AppColors.surface, AppColors.darkSurface);
      expect(AppColors.textPrimary, AppColors.darkTextPrimary);
      expect(notifiedCount, 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_dark_mode'), isTrue);

      await provider.toggleTheme(false);

      expect(provider.isDarkMode, isFalse);
      expect(provider.themeMode, ThemeMode.light);
      expect(AppColors.isDarkMode, isFalse);
      expect(AppColors.background, AppColors.lightBackground);
      expect(notifiedCount, 2);
      expect(prefs.getBool('is_dark_mode'), isFalse);
    });
  });
}
