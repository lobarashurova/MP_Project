/// Map and geocoding settings.
///
/// The map is Yandex MapKit (lite edition): the map itself and a pin, under
/// Yandex's free MapKit licence. No routing is used.
///
/// Address search and "what address is under this pin" use Nominatim
/// (https://nominatim.org), the free OpenStreetMap geocoder, because Yandex's
/// own search and geocoding are part of its paid licence. Nominatim allows at
/// most one request per second, requires a User-Agent that identifies the
/// app, and asks clients to cache results; GeocodingRepository enforces all
/// three.
class MapConfig {
  MapConfig._();

  /// Yandex MapKit API key, supplied at build time so it never lands in git:
  ///
  ///   flutter run --dart-define=YANDEX_MAPKIT_API_KEY=your-key
  ///
  /// or put it in a git-ignored JSON file and pass
  /// --dart-define-from-file=keys.json. Without a key the app still works,
  /// and the checkout simply hides the "Choose on map" button.
  static const String yandexApiKey = String.fromEnvironment('YANDEX_MAPKIT_API_KEY');

  static bool get isMapAvailable => yandexApiKey.isNotEmpty;

  /// Where the map opens when we don't know the user's location: central
  /// Tashkent (Amir Temur Square).
  static const double defaultLatitude = 41.3111;
  static const double defaultLongitude = 69.2797;
  static const double defaultZoom = 12;

  /// Zoom used after picking a search result or the user's location, close
  /// enough to see individual buildings.
  static const double streetZoom = 17;

  static const String nominatimBaseUrl = 'https://nominatim.openstreetmap.org';

  /// Required by the Nominatim usage policy. Identifies the app and gives a
  /// way to reach its maintainers.
  static const String userAgent =
      'Xurmo/1.0 (CS363 student project; https://github.com/lobarashurova/MP_Project)';

  /// Nominatim's results are OpenStreetMap data and must be credited.
  static const String geocodingAttribution = 'Addresses © OpenStreetMap contributors';

  /// Search results are limited to Uzbekistan, where Xurmo delivers.
  static const String countryCodes = 'uz';

  /// Minimum gap between Nominatim requests, per its usage policy.
  static const Duration nominatimMinInterval = Duration(milliseconds: 1100);
}
