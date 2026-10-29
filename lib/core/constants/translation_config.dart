/// Settings for translating menu text (dish names, categories, ingredients)
/// with the From-To translation API (https://from-to.uz).
///
/// The menu comes from TheMealDB in English. When the app language is Russian
/// or Uzbek, menu text is translated in the background. Translation is purely
/// best-effort: if the API is down, a key runs out, or no key is configured,
/// the English text simply stays on screen and nothing else changes.
class TranslationConfig {
  TranslationConfig._();

  static const String endpoint = 'https://api.from-to.uz/api/v1/external/translate';

  /// API keys, supplied at build time so they never land in git. Several keys
  /// can be given, separated by commas. Each free key allows about 50
  /// requests a day; when one runs out the next one is used automatically.
  ///
  ///   keys.json: { "FROM_TO_API_KEYS": "ft_key_one,ft_key_two" }
  ///   flutter run --dart-define-from-file=keys.json
  static const String _rawKeys = String.fromEnvironment('FROM_TO_API_KEYS');

  static List<String> get apiKeys => _rawKeys
      .split(',')
      .map((k) => k.trim())
      .where((k) => k.isNotEmpty)
      .toList(growable: false);

  static bool get isEnabled => apiKeys.isNotEmpty;

  /// The menu's own language.
  static const String sourceLanguage = 'eng_Latn';

  /// API language code for an app language, or null when no translation is
  /// needed (English) or the language is not supported.
  static String? targetFor(String appLanguageCode) {
    switch (appLanguageCode) {
      case 'ru':
        return 'rus_Cyrl';
      case 'uz':
        return 'uzn_Latn';
      default:
        return null;
    }
  }

  /// How long one request may take before it counts as failed.
  static const Duration requestTimeout = Duration(seconds: 15);

  /// After the service itself fails (server errors, timeouts, no internet),
  /// stop calling it for a while so screens are not slowed down and requests
  /// are not wasted.
  static const Duration outagePause = Duration(minutes: 5);

  /// Texts requested within this window are sent together in one request,
  /// so a whole screen of dish names costs one request instead of twenty.
  static const Duration batchWindow = Duration(milliseconds: 200);

  /// Upper limit on the size of one batched request.
  static const int maxBatchChars = 1500;
}
