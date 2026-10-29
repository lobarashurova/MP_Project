import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xurmo/core/constants/translation_config.dart';
import 'package:xurmo/core/translation/menu_translator.dart';
import 'package:xurmo/presentation/profile/settings_provider.dart';

/// Shows menu text (a dish name, category, ingredient...) in the app's
/// language when a translation is available, and the original English text
/// otherwise.
///
/// The English text appears immediately. A translation replaces it when it
/// arrives; if it never does, because the API is down, out of requests or
/// not configured, the English text simply stays. No error is ever shown.
///
/// Use it like [Text]. Only menu data from the API should go through it;
/// fixed app wording belongs in the app's own language strings.
class TranslatedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool? softWrap;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.softWrap,
  });

  @override
  State<TranslatedText> createState() => _TranslatedTextState();
}

class _TranslatedTextState extends State<TranslatedText> {
  String? _translated;
  String? _shownText;
  String? _shownTarget;

  /// The app language, or English when there is no settings provider above
  /// this widget, as in some tests.
  String _languageOf(BuildContext context) {
    try {
      return context.watch<SettingsProvider>().locale.languageCode;
    } on ProviderNotFoundException {
      return 'en';
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = TranslationConfig.targetFor(_languageOf(context));
    final text = widget.text;

    final translator = MenuTranslator.instance;
    if (target != null && translator.isEnabled && text.trim().isNotEmpty) {
      if (text != _shownText || target != _shownTarget) {
        _shownText = text;
        _shownTarget = target;
        _translated = translator.cached(text, target);
        if (_translated == null) {
          translator.request(text, target).then((value) {
            if (!mounted || value == null) return;
            // Ignore a late answer for text this widget no longer shows.
            if (_shownText != text || _shownTarget != target) return;
            setState(() => _translated = value);
          });
        }
      }
    } else {
      _shownText = null;
      _shownTarget = null;
      _translated = null;
    }

    return Text(
      _translated ?? text,
      style: widget.style,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textAlign: widget.textAlign,
      softWrap: widget.softWrap,
    );
  }
}
