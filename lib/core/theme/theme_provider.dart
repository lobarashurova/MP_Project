import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xurmo/core/constants/app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _keyDarkMode = 'is_dark_mode';

  ThemeMode _themeMode;

  ThemeProvider({bool initialIsDarkMode = false})
      : _themeMode = initialIsDarkMode ? ThemeMode.dark : ThemeMode.light {
    AppColors.isDarkMode = initialIsDarkMode;
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> toggleTheme(bool isDark) async {
    if (isDarkMode == isDark) return;

    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    AppColors.isDarkMode = isDark;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyDarkMode, isDark);
    } catch (e) {
      debugPrint('Failed to save theme setting: $e');
    }
  }
}
