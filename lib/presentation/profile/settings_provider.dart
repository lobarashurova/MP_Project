import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppFontSize { small, medium, large }

class SettingsProvider extends ChangeNotifier {
  static const languages = {
    'en': 'English',
    'ru': 'Русский',
    'uz': "O'zbekcha",
  };

  static const _localeKey = 'settings_locale';
  static const _fontKey = 'settings_font_size';

  Locale _locale = const Locale('en');
  AppFontSize _fontSize = AppFontSize.medium;

  Locale get locale => _locale;
  AppFontSize get fontSize => _fontSize;
  String get languageName => languages[_locale.languageCode] ?? 'English';

  double get textScale {
    switch (_fontSize) {
      case AppFontSize.small:
        return 0.9;
      case AppFontSize.medium:
        return 1.0;
      case AppFontSize.large:
        return 1.15;
    }
  }

  /// Call once before runApp so the saved choices apply from the first frame.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_localeKey);
      if (code != null && languages.containsKey(code)) {
        _locale = Locale(code);
      }
      final font = prefs.getString(_fontKey);
      _fontSize = AppFontSize.values.firstWhere(
            (f) => f.name == font,
        orElse: () => AppFontSize.medium,
      );
    } catch (_) {
      // Fall back to the defaults if storage can't be read.
    }
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
    } catch (_) {}
  }

  Future<void> setFontSize(AppFontSize size) async {
    _fontSize = size;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fontKey, size.name);
    } catch (_) {}
  }
}
