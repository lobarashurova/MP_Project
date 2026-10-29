import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xurmo/data/repositories/translation_repository.dart';

/// Answers translation requests from a handler instead of the network.
class _FakeApi implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  ({int status, Object body}) Function(RequestOptions options, String text, String key) handler;

  _FakeApi(this.handler);

  static String textOf(RequestOptions o) => ((o.data as Map)['body'] as Map)['text'] as String;
  static String keyOf(RequestOptions o) => '${o.headers['Authorization']}'.replaceFirst('Bearer ', '');

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final reply = handler(options, textOf(options), keyOf(options));
    return ResponseBody.fromString(jsonEncode(reply.body), reply.status,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  void close({bool force = false}) {}
}

/// Pretends to translate by adding a marker to every line, keeping lines apart.
String _fakeTranslate(String text) => text.split('\n').map((l) => 'RU($l)').join('\n');

void main() {
  late MemoryTranslationStore store;
  late DateTime clock;

  TranslationRepository repo(_FakeApi api, {List<String> keys = const ['key-1']}) {
    return TranslationRepository(
      store: store,
      dio: Dio()..httpClientAdapter = api,
      apiKeys: keys,
      now: () => clock,
    );
  }

  setUp(() {
    store = MemoryTranslationStore();
    clock = DateTime.utc(2026, 10, 29, 12);
  });

  test('sends several names in one request and caches every result', () async {
    final api = _FakeApi((o, text, key) => (status: 200, body: {'result': _fakeTranslate(text)}));
    final r = repo(api);

    final result = await r.translate(['Beef Stroganoff', 'Chicken', 'Seafood'], 'rus_Cyrl');

    expect(result, {
      'Beef Stroganoff': 'RU(Beef Stroganoff)',
      'Chicken': 'RU(Chicken)',
      'Seafood': 'RU(Seafood)',
    });
    expect(api.requests, hasLength(1), reason: 'one batched request for the whole screen');
    expect(r.cached('Chicken', 'rus_Cyrl'), 'RU(Chicken)');
  });

  test('sends the right request format with the key as a Bearer header', () async {
    final api = _FakeApi((o, text, key) => (status: 200, body: {'result': _fakeTranslate(text)}));
    await repo(api).translate(['Chicken'], 'uzn_Latn');

    final o = api.requests.single;
    expect(o.uri.toString(), 'https://api.from-to.uz/api/v1/external/translate');
    expect(o.headers['Authorization'], 'Bearer key-1');
    final body = (o.data as Map)['body'] as Map;
    expect(body['lang_from'], 'eng_Latn');
    expect(body['lang_to'], 'uzn_Latn');
    expect(body['text'], 'Chicken');
  });

  test('cached texts cost no request, even after a restart', () async {
    final api = _FakeApi((o, text, key) => (status: 200, body: {'result': _fakeTranslate(text)}));
    await repo(api).translate(['Chicken'], 'rus_Cyrl');

    // A new repository with the same store behaves like the app after a restart.
    final again = await repo(api).translate(['Chicken'], 'rus_Cyrl');
    expect(again['Chicken'], 'RU(Chicken)');
    expect(api.requests, hasLength(1));
  });

  test('falls back to one text per request if the API merges lines', () async {
    final api = _FakeApi((o, text, key) =>
        (status: 200, body: {'result': text.contains('\n') ? 'one merged line' : 'RU($text)'}));
    final r = repo(api);

    final result = await r.translate(['Chicken', 'Beef'], 'rus_Cyrl');

    expect(result, {'Chicken': 'RU(Chicken)', 'Beef': 'RU(Beef)'});
    expect(api.requests, hasLength(3), reason: 'one failed batch, then two single requests');

    // Batching stays off from now on, even for a new repository.
    api.requests.clear();
    await repo(api).translate(['Lamb', 'Pork'], 'rus_Cyrl');
    expect(api.requests.map(_FakeApi.textOf), ['Lamb', 'Pork']);
  });

  test('text with line breaks is never mixed into a batch', () async {
    final api = _FakeApi((o, text, key) => (status: 200, body: {'result': 'RU'}));
    await repo(api).translate(['Step one.\nStep two.', 'Chicken'], 'rus_Cyrl');
    expect(api.requests.map(_FakeApi.textOf), containsAll(['Step one.\nStep two.', 'Chicken']));
  });

  group('API keys', () {
    test('switches to the second key when the first runs out', () async {
      final api = _FakeApi((o, text, key) => key == 'key-1'
          ? (status: 429, body: {'success': false, 'message': 'Rate limit exceeded'})
          : (status: 200, body: {'result': _fakeTranslate(text)}));
      final r = repo(api, keys: ['key-1', 'key-2']);

      expect((await r.translate(['Chicken'], 'rus_Cyrl'))['Chicken'], 'RU(Chicken)');
      expect(api.requests.map(_FakeApi.keyOf), ['key-1', 'key-2']);

      // The used-up key is skipped for the rest of the day, even after a restart.
      api.requests.clear();
      await repo(api, keys: ['key-1', 'key-2']).translate(['Beef'], 'rus_Cyrl');
      expect(api.requests.map(_FakeApi.keyOf), ['key-2']);
    });

    test('a refused key (401/403) is also skipped', () async {
      final api = _FakeApi((o, text, key) => key == 'key-1'
          ? (status: 403, body: {'success': false, 'message': 'API access not available'})
          : (status: 200, body: {'result': _fakeTranslate(text)}));
      final result = await repo(api, keys: ['key-1', 'key-2']).translate(['Chicken'], 'rus_Cyrl');
      expect(result['Chicken'], 'RU(Chicken)');
    });

    test('when every key has run out, nothing is sent and English stays', () async {
      final api = _FakeApi((o, text, key) => (status: 429, body: {'message': 'limit'}));
      final r = repo(api, keys: ['key-1', 'key-2']);

      expect(await r.translate(['Chicken'], 'rus_Cyrl'), isEmpty);
      expect(api.requests, hasLength(2));

      api.requests.clear();
      expect(await r.translate(['Beef'], 'rus_Cyrl'), isEmpty);
      expect(api.requests, isEmpty, reason: 'no requests once all keys are used up');
    });

    test('a used-up key comes back the next day', () async {
      var limitHit = true;
      final api = _FakeApi((o, text, key) => limitHit
          ? (status: 429, body: {'message': 'limit'})
          : (status: 200, body: {'result': _fakeTranslate(text)}));
      final r = repo(api);

      expect(await r.translate(['Chicken'], 'rus_Cyrl'), isEmpty);

      limitHit = false;
      clock = clock.add(const Duration(days: 1));
      expect((await r.translate(['Chicken'], 'rus_Cyrl'))['Chicken'], 'RU(Chicken)');
    });
  });

  group('service problems never reach the screen', () {
    test('a server error pauses translation instead of retrying', () async {
      var down = true;
      final api = _FakeApi((o, text, key) => down
          ? (status: 500, body: {'error': 'NLLB error: status 503: service unavailable'})
          : (status: 200, body: {'result': _fakeTranslate(text)}));
      final r = repo(api);

      expect(await r.translate(['Chicken'], 'rus_Cyrl'), isEmpty);
      expect(api.requests, hasLength(1));

      // Still within the pause: nothing is sent, the key is not wasted.
      down = false;
      clock = clock.add(const Duration(minutes: 2));
      expect(await r.translate(['Beef'], 'rus_Cyrl'), isEmpty);
      expect(api.requests, hasLength(1));

      // After the pause, translation resumes.
      clock = clock.add(const Duration(minutes: 5));
      expect((await r.translate(['Beef'], 'rus_Cyrl'))['Beef'], 'RU(Beef)');
    });

    test('a server error does not use up the key', () async {
      final api = _FakeApi((o, text, key) => (status: 504, body: {'error': 'gateway timeout'}));
      final r = repo(api, keys: ['key-1', 'key-2']);
      await r.translate(['Chicken'], 'rus_Cyrl');
      expect(api.requests.map(_FakeApi.keyOf), ['key-1'], reason: 'key-2 is kept for later');
    });

    test('an empty or odd response leaves English and does not throw', () async {
      final api = _FakeApi((o, text, key) => (status: 200, body: {'unexpected': true}));
      expect(await repo(api).translate(['Chicken'], 'rus_Cyrl'), isEmpty);
    });

    test('with no key configured nothing is sent', () async {
      final api = _FakeApi((o, text, key) => (status: 200, body: {'result': 'x'}));
      final r = repo(api, keys: const []);
      expect(r.isEnabled, isFalse);
      expect(await r.translate(['Chicken'], 'rus_Cyrl'), isEmpty);
      expect(api.requests, isEmpty);
    });
  });

  test('blank texts are ignored', () async {
    final api = _FakeApi((o, text, key) => (status: 200, body: {'result': _fakeTranslate(text)}));
    expect(await repo(api).translate(['', '   '], 'rus_Cyrl'), isEmpty);
    expect(api.requests, isEmpty);
  });
}
