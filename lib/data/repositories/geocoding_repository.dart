import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:xurmo/core/constants/map_config.dart';
import 'package:xurmo/data/models/delivery_location.dart';

/// Thrown when an address lookup fails, with a message safe to show.
class GeocodingFailure implements Exception {
  final String message;
  const GeocodingFailure(this.message);

  @override
  String toString() => message;
}

/// Address search and reverse lookup through the public Nominatim service.
///
/// The Nominatim usage policy is enforced here so callers can't break it:
///   - every request carries a User-Agent that identifies Xurmo;
///   - requests are spaced at least [MapConfig.nominatimMinInterval] apart,
///     queued rather than dropped;
///   - results are cached in memory, so panning back to a spot or repeating a
///     search costs no request.
class GeocodingRepository {
  final Dio _dio;
  final Duration _minInterval;

  GeocodingRepository({Dio? dio, Duration? minInterval})
      : _dio = dio ?? _defaultDio(),
        _minInterval = minInterval ?? MapConfig.nominatimMinInterval;

  static Dio _defaultDio() {
    return Dio(BaseOptions(
      baseUrl: MapConfig.nominatimBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent': MapConfig.userAgent,
        'Accept': 'application/json',
      },
    ));
  }

  static const int _cacheSize = 100;
  final LinkedHashMap<String, Object> _cache = LinkedHashMap();

  /// Completes when the previous request's slot has passed. Chaining on it
  /// queues concurrent callers one after another.
  Future<void> _lastSlot = Future.value();
  DateTime _lastRequestAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Finds places matching [query] in Uzbekistan, best match first.
  Future<List<DeliveryLocation>> search(String query) async {
    final q = query.trim();
    if (q.length < 3) return const [];

    final key = 'search:${q.toLowerCase()}';
    final cached = _cache[key];
    if (cached is List<DeliveryLocation>) return cached;

    final data = await _get('/search', {
      'q': q,
      'format': 'jsonv2',
      'addressdetails': 1,
      'limit': 8,
      'countrycodes': MapConfig.countryCodes,
      'accept-language': 'en',
    });

    final results = parseSearchResponse(data);
    _remember(key, results);
    return results;
  }

  /// Returns the address at a point, or null when nothing is there.
  Future<DeliveryLocation?> reverse(double latitude, double longitude) async {
    // Five decimals is about one metre, so tiny camera jitter hits the cache.
    final key = 'reverse:${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}';
    final cached = _cache[key];
    if (cached is DeliveryLocation) return cached;
    if (cached == _noResult) return null;

    final data = await _get('/reverse', {
      'lat': latitude,
      'lon': longitude,
      'format': 'jsonv2',
      'addressdetails': 1,
      'zoom': 18,
      'accept-language': 'en',
    });

    final place = parseReverseResponse(data);
    // Keep the exact point the user chose, not the geocoder's snapped one,
    // so the courier goes to the pin rather than the middle of the street.
    final result = place == null
        ? null
        : DeliveryLocation(
            latitude: latitude,
            longitude: longitude,
            address: place.address,
            fullAddress: place.fullAddress,
          );
    _remember(key, result ?? _noResult);
    return result;
  }

  static const Object _noResult = Object();

  void _remember(String key, Object value) {
    _cache.remove(key);
    _cache[key] = value;
    if (_cache.length > _cacheSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  Future<dynamic> _get(String path, Map<String, dynamic> params) async {
    final slot = _lastSlot.then((_) async {
      final wait = _minInterval - DateTime.now().difference(_lastRequestAt);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      _lastRequestAt = DateTime.now();
    });
    // A failed request must not block the queue for everyone after it.
    _lastSlot = slot.catchError((_) {});
    await slot;

    try {
      final response = await _dio.get<dynamic>(path, queryParameters: params);
      return response.data;
    } on DioException catch (e) {
      throw GeocodingFailure(_messageFor(e));
    }
  }

  static String _messageFor(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'No internet connection. Check your network and try again.';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        if (status == 429 || status == 403) {
          return 'Address search is busy right now. Try again in a moment.';
        }
        return 'Address search is unavailable right now.';
      default:
        return 'Could not look up the address. Please try again.';
    }
  }

  /// Parses a /search response body into locations, skipping bad entries.
  static List<DeliveryLocation> parseSearchResponse(dynamic data) {
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => DeliveryLocation.fromNominatim(Map<String, dynamic>.from(e)))
        .whereType<DeliveryLocation>()
        .toList(growable: false);
  }

  /// Parses a /reverse response body. Nominatim answers an empty spot, such
  /// as the middle of a lake, with {"error": "Unable to geocode"}.
  static DeliveryLocation? parseReverseResponse(dynamic data) {
    if (data is! Map || data.containsKey('error')) return null;
    return DeliveryLocation.fromNominatim(Map<String, dynamic>.from(data));
  }
}
