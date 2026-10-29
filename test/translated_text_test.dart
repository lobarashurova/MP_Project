import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xurmo/core/translation/menu_translator.dart';
import 'package:xurmo/core/translation/translated_text.dart';
import 'package:xurmo/data/repositories/translation_repository.dart';
import 'package:xurmo/presentation/profile/settings_provider.dart';

class _FakeApi implements HttpClientAdapter {
  int calls = 0;
  final int status;
  _FakeApi({this.status = 200});

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    calls++;
    final text = ((o.data as Map)['body'] as Map)['text'] as String;
    final body = status == 200
        ? {'result': text.split('\n').map((l) => 'RU($l)').join('\n')}
        : {'error': 'service unavailable'};
    return ResponseBody.fromString(jsonEncode(body), status,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeApi api;

  void useTranslator({int status = 200}) {
    api = _FakeApi(status: status);
    MenuTranslator.debugInstance = MenuTranslator(TranslationRepository(
      store: MemoryTranslationStore(),
      dio: Dio()..httpClientAdapter = api,
      apiKeys: const ['key-1'],
    ));
  }

  // Changing the language saves it; give the tests an in-memory store.
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => MenuTranslator.debugInstance = null);

  Future<SettingsProvider> pumpWithLanguage(WidgetTester tester, String code, Widget child) async {
    final settings = SettingsProvider();
    await settings.setLocale(Locale(code));
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: settings,
      child: MaterialApp(home: Scaffold(body: child)),
    ));
    return settings;
  }

  /// Lets the batch timer fire and the fake API answer.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
  }

  testWidgets('English shows the original and sends nothing', (tester) async {
    useTranslator();
    await pumpWithLanguage(tester, 'en', const TranslatedText('Chicken'));
    await settle(tester);

    expect(find.text('Chicken'), findsOneWidget);
    expect(api.calls, 0);
  });

  testWidgets('Russian shows English first, then the translation', (tester) async {
    useTranslator();
    await pumpWithLanguage(tester, 'ru', const TranslatedText('Chicken'));

    expect(find.text('Chicken'), findsOneWidget, reason: 'English is shown while waiting');

    await settle(tester);
    expect(find.text('RU(Chicken)'), findsOneWidget);
  });

  testWidgets('a whole screen of texts goes out as one request', (tester) async {
    useTranslator();
    await pumpWithLanguage(
      tester,
      'ru',
      const Column(children: [TranslatedText('Chicken'), TranslatedText('Beef'), TranslatedText('Seafood')]),
    );
    await settle(tester);

    expect(find.text('RU(Chicken)'), findsOneWidget);
    expect(find.text('RU(Beef)'), findsOneWidget);
    expect(find.text('RU(Seafood)'), findsOneWidget);
    expect(api.calls, 1);
  });

  testWidgets('when the API fails the English text simply stays', (tester) async {
    useTranslator(status: 500);
    await pumpWithLanguage(tester, 'ru', const TranslatedText('Chicken'));
    await settle(tester);

    expect(find.text('Chicken'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('switching back to English shows the original again', (tester) async {
    useTranslator();
    final settings = await pumpWithLanguage(tester, 'ru', const TranslatedText('Chicken'));
    await settle(tester);
    expect(find.text('RU(Chicken)'), findsOneWidget);

    await settings.setLocale(const Locale('en'));
    await tester.pump();
    expect(find.text('Chicken'), findsOneWidget);
  });

  testWidgets('works without a language setting, showing English', (tester) async {
    useTranslator();
    await tester.pumpWidget(const MaterialApp(home: TranslatedText('Chicken')));
    await settle(tester);

    expect(find.text('Chicken'), findsOneWidget);
    expect(api.calls, 0);
  });
}
