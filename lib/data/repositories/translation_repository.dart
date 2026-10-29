import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:xurmo/core/constants/translation_config.dart';

/// Where translations and API key state are kept between app launches.
abstract class TranslationStore {
  Object? get(String key);
  Future<void> put(String key, Object value);
}

/// Stores everything in a Hive box on the phone.
class HiveTranslationStore implements TranslationStore {
  static const String boxName = 'translations';

  Box<dynamic>? _box;

  /// Opens the box. Until it is open, reads return nothing and writes are
  /// skipped, so a failure here only means translations are not cached.
  Future<void> open() async {
    if (_box != null) return;
    try {
      _box = Hive.isBoxOpen(boxName) ? Hive.box(boxName) : await Hive.openBox(boxName);
    } catch (e) {
      debugPrint('Translation cache unavailable: $e');
    }
  }

  @override
  Object? get(String key) => _box?.get(key);

  @override
  Future<void> put(String key, Object value) async {
    try {
      await _box?.put(key, value);
    } catch (e) {
      debugPrint('Could not save translation: $e');
    }
  }
}

/// Keeps everything in memory. Used by tests.
class MemoryTranslationStore implements TranslationStore {
  final Map<String, Object> values = {};

  @override
  Object? get(String key) => values[key];

  @override
  Future<void> put(String key, Object value) async => values[key] = value;
}

/// Translates menu text with the From-To API, as cheaply and safely as
/// possible.
///
/// Guarantees:
///   - It never throws. Whatever cannot be translated is simply missing from
///     the result, and the caller keeps showing the English text.
///   - Every translation is cached on the phone, so each text costs one
///     request at most, ever.
///   - Several short texts are sent in one request, one per line, when the
///     API keeps the lines apart. If it ever merges them, batching is turned
///     off for good and texts are sent one by one.
///   - When a key runs out (HTTP 429) or is refused (401/403), it is skipped
///     until the next day and the next key is used.
///   - When the service itself fails (server errors, timeouts, no internet),
///     nothing is sent for [TranslationConfig.outagePause].
class TranslationRepository {
  final TranslationStore _store;
  final Dio _dio;
  final List<String> _keys;
  final DateTime Function() _now;

  TranslationRepository({
    required TranslationStore store,
    Dio? dio,
    List<String>? apiKeys,
    DateTime Function()? now,
  })  : _store = store,
        _dio = dio ?? Dio(),
        _keys = apiKeys ?? TranslationConfig.apiKeys,
        _now = now ?? DateTime.now;

  DateTime? _pausedUntil;

  bool get isEnabled => _keys.isNotEmpty;

  // ------------------------------------------------------------- Cache

  static String _cacheKey(String target, String text) =>
      'tr:$target:${_fingerprint(text)}';

  /// The cached translation of [text], or null if it was never translated.
  String? cached(String text, String target) {
    final entry = _store.get(_cacheKey(target, text));
    // The original text is stored too, so a rare hash collision can never
    // show the wrong dish name.
    if (entry is Map && entry['s'] == text && entry['t'] is String) {
      return entry['t'] as String;
    }
    return null;
  }

  Future<void> _remember(String text, String target, String translated) =>
      _store.put(_cacheKey(target, text), {'s': text, 't': translated});

  // -------------------------------------------------------------- Keys

  static String _keyStateKey(String apiKey) => 'key:${_fingerprint(apiKey)}';

  /// The first key that has not run out today, or null if all have.
  String? _usableKey() {
    final now = _now();
    for (final key in _keys) {
      final until = DateTime.tryParse('${_store.get(_keyStateKey(key)) ?? ''}');
      if (until == null || !now.isBefore(until)) return key;
    }
    return null;
  }

  /// Skips [apiKey] until the start of the next day (UTC), when free quotas
  /// usually reset. If the reset is later, the next attempt just marks it
  /// again, which costs one refused request.
  Future<void> _retireForToday(String apiKey) {
    final now = _now().toUtc();
    final tomorrow = DateTime.utc(now.year, now.month, now.day + 1);
    return _store.put(_keyStateKey(apiKey), tomorrow.toIso8601String());
  }

  // ---------------------------------------------------------- Batching

  static const String _batchingKey = 'mode:batching';

  bool get _batchingSupported => _store.get(_batchingKey) != 'unsupported';

  // ---------------------------------------------------------- Translate

  /// Translates [texts] into [target] and returns the ones that succeeded,
  /// keyed by the original text. Cached texts cost nothing.
  Future<Map<String, String>> translate(List<String> texts, String target) async {
    final result = <String, String>{};
    final pending = <String>[];

    for (final text in texts.toSet()) {
      if (text.trim().isEmpty) continue;
      final hit = cached(text, target);
      if (hit != null) {
        result[text] = hit;
      } else {
        pending.add(text);
      }
    }

    if (pending.isEmpty || !isEnabled || _isPaused) return result;

    final queue = _plan(pending);
    while (queue.isNotEmpty) {
      final group = queue.removeAt(0);
      final response = await _send(group.join('\n'), target);
      if (response == null) break; // Out of keys or service down: stop here.

      if (group.length == 1) {
        final translated = response.trim();
        if (translated.isNotEmpty) {
          result[group.single] = translated;
          await _remember(group.single, target, translated);
        }
        continue;
      }

      final lines = response.split('\n');
      if (lines.length == group.length) {
        for (var i = 0; i < group.length; i++) {
          final translated = lines[i].trim();
          if (translated.isEmpty) continue;
          result[group[i]] = translated;
          await _remember(group[i], target, translated);
        }
      } else {
        // The API did not keep one line per text, so batching cannot be
        // trusted. Turn it off for good and send these texts one by one.
        debugPrint('Translation: batched lines did not match, switching to single texts');
        await _store.put(_batchingKey, 'unsupported');
        queue.insertAll(0, group.map((t) => [t]));
      }
    }
    return result;
  }

  /// Splits texts into requests. Texts containing line breaks always go
  /// alone, because line breaks separate texts inside a batch.
  List<List<String>> _plan(List<String> texts) {
    if (!_batchingSupported) return texts.map((t) => [t]).toList();

    final groups = <List<String>>[];
    var current = <String>[];
    var size = 0;
    for (final text in texts) {
      if (text.contains('\n') || text.length >= TranslationConfig.maxBatchChars) {
        groups.add([text]);
        continue;
      }
      if (current.isNotEmpty && size + text.length + 1 > TranslationConfig.maxBatchChars) {
        groups.add(current);
        current = <String>[];
        size = 0;
      }
      current.add(text);
      size += text.length + 1;
    }
    if (current.isNotEmpty) groups.add(current);
    return groups;
  }

  bool get _isPaused {
    final until = _pausedUntil;
    return until != null && _now().isBefore(until);
  }

  void _pause(String reason) {
    _pausedUntil = _now().add(TranslationConfig.outagePause);
    debugPrint('Translation paused for ${TranslationConfig.outagePause.inMinutes} min: $reason');
  }

  /// Sends one request, moving to the next key when one runs out. Returns
  /// the translated text, or null when nothing could be translated.
  Future<String?> _send(String text, String target) async {
    while (true) {
      final key = _usableKey();
      if (key == null) {
        debugPrint('Translation: all API keys have run out for today');
        return null;
      }

      try {
        final response = await _dio.post<dynamic>(
          TranslationConfig.endpoint,
          data: {
            'body': {
              'lang_from': TranslationConfig.sourceLanguage,
              'lang_to': target,
              'resultCase': 'latn',
              'text': text,
            },
          },
          options: Options(
            headers: {'Authorization': 'Bearer $key', 'Accept': 'application/json'},
            contentType: Headers.jsonContentType,
            sendTimeout: TranslationConfig.requestTimeout,
            receiveTimeout: TranslationConfig.requestTimeout,
          ),
        );
        final data = response.data;
        final translated = data is Map ? data['result'] : null;
        if (translated is String && translated.trim().isNotEmpty) return translated;
        _pause('unexpected response');
        return null;
      } on DioException catch (e) {
        final status = e.response?.statusCode;
        final body = '${e.response?.data ?? ''}'.toLowerCase();
        final outOfQuota = status == 429 ||
            ((status == 400 || status == 402) && (body.contains('limit') || body.contains('quota')));
        final keyRefused = status == 401 || status == 403;

        if (outOfQuota || keyRefused) {
          debugPrint('Translation: key ${_keys.indexOf(key) + 1} '
              '${outOfQuota ? 'ran out' : 'was refused'} (HTTP $status), trying the next one');
          await _retireForToday(key);
          continue;
        }

        _pause(status == null ? 'no connection or timeout' : 'HTTP $status');
        return null;
      } catch (e) {
        _pause('$e');
        return null;
      }
    }
  }
}

/// Short, stable fingerprint of a string, used for storage keys. Two
/// independent 32-bit FNV-1a hashes give a 64-bit result that does not depend
/// on the platform's integer size.
String _fingerprint(String value) {
  var a = 0x811c9dc5;
  var b = 0x01000193 ^ value.length;
  for (final unit in value.codeUnits) {
    a = ((a ^ unit) * 0x01000193) & 0xffffffff;
    b = ((b ^ unit) * 0x01000193 + 0x9e3779b9) & 0xffffffff;
  }
  return a.toRadixString(16).padLeft(8, '0') + b.toRadixString(16).padLeft(8, '0');
}
