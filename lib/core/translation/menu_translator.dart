import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:xurmo/core/constants/translation_config.dart';
import 'package:xurmo/data/repositories/translation_repository.dart';

/// Collects translation requests from all widgets on screen and sends them
/// together, so one screen of dishes costs one API request.
///
/// It is safe to use anywhere: when translation is off or fails, requests
/// simply complete with null and the English text stays.
class MenuTranslator {
  MenuTranslator(this._repository);

  static MenuTranslator? _instance;
  static HiveTranslationStore? _hiveStore;

  /// The app-wide translator. Call [warmUp] once at startup so cached
  /// translations show immediately instead of after the first frame.
  static MenuTranslator get instance {
    return _instance ??= MenuTranslator(
      TranslationRepository(store: _hiveStore ??= HiveTranslationStore()),
    );
  }

  /// Opens the translation cache. Harmless when translation is disabled.
  static Future<void> warmUp() async {
    if (!TranslationConfig.isEnabled) return;
    await (_hiveStore ??= HiveTranslationStore()).open();
    instance;
  }

  /// Replaces the shared instance. For tests only.
  @visibleForTesting
  static set debugInstance(MenuTranslator? translator) => _instance = translator;

  final TranslationRepository _repository;

  bool get isEnabled => _repository.isEnabled;

  /// Cached translation, available instantly, or null.
  String? cached(String text, String target) => _repository.cached(text, target);

  final Map<String, Map<String, Completer<String?>>> _pending = {};
  Timer? _flushTimer;

  /// Asks for a translation. Completes with null when it is not available.
  Future<String?> request(String text, String target) {
    final hit = cached(text, target);
    if (hit != null || !isEnabled) return Future.value(hit);

    final byText = _pending.putIfAbsent(target, () => {});
    final existing = byText[text];
    if (existing != null) return existing.future;

    final completer = Completer<String?>();
    byText[text] = completer;
    _flushTimer ??= Timer(TranslationConfig.batchWindow, _flush);
    return completer.future;
  }

  Future<void> _flush() async {
    _flushTimer = null;
    final batches = Map.of(_pending);
    _pending.clear();

    for (final entry in batches.entries) {
      final target = entry.key;
      final completers = entry.value;
      Map<String, String> translated = const {};
      try {
        translated = await _repository.translate(completers.keys.toList(), target);
      } catch (e) {
        // The repository never throws, but the screen must not depend on it.
        debugPrint('Translation failed: $e');
      }
      completers.forEach((text, completer) {
        if (!completer.isCompleted) completer.complete(translated[text]);
      });
    }
  }
}
