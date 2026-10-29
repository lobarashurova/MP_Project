import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xurmo/core/constants/map_config.dart';
import 'package:xurmo/data/repositories/geocoding_repository.dart';

/// Answers requests from a handler instead of the network, and records them.
class _FakeAdapter implements HttpClientAdapter {
  final List<RequestOptions> requests = [];
  final List<DateTime> times = [];
  ({int status, Object body}) Function(RequestOptions options) handler;

  _FakeAdapter(this.handler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    times.add(DateTime.now());
    final reply = handler(options);
    return ResponseBody.fromString(
      jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

GeocodingRepository _repo(_FakeAdapter adapter, {Duration? minInterval}) {
  final dio = Dio(BaseOptions(
    baseUrl: MapConfig.nominatimBaseUrl,
    headers: {'User-Agent': MapConfig.userAgent},
  ))
    ..httpClientAdapter = adapter;
  return GeocodingRepository(dio: dio, minInterval: minInterval ?? Duration.zero);
}

const _searchBody = [
  {
    'lat': '41.3111',
    'lon': '69.2797',
    'display_name': 'Amir Temur Square, Tashkent, Uzbekistan',
    'address': {'road': 'Amir Temur Avenue', 'city': 'Tashkent'},
  },
  {'display_name': 'broken entry without coordinates'},
];

void main() {
  test('search sends the Nominatim policy parameters and parses results', () async {
    final adapter = _FakeAdapter((_) => (status: 200, body: _searchBody));
    final results = await _repo(adapter).search('amir temur');

    expect(results, hasLength(1));
    expect(results.single.address, 'Amir Temur Avenue, Tashkent');

    final request = adapter.requests.single;
    expect(request.path, '/search');
    expect(request.queryParameters['q'], 'amir temur');
    expect(request.queryParameters['countrycodes'], 'uz');
    expect(request.queryParameters['format'], 'jsonv2');
    expect(request.headers['User-Agent'], contains('Xurmo'));
  });

  test('search skips queries shorter than 3 characters without a request', () async {
    final adapter = _FakeAdapter((_) => (status: 200, body: _searchBody));
    expect(await _repo(adapter).search('am'), isEmpty);
    expect(adapter.requests, isEmpty);
  });

  test('repeated searches are served from the cache', () async {
    final adapter = _FakeAdapter((_) => (status: 200, body: _searchBody));
    final repo = _repo(adapter);
    await repo.search('Amir Temur');
    await repo.search('  amir temur ');
    expect(adapter.requests, hasLength(1));
  });

  test('reverse keeps the exact pinned point, not the geocoder point', () async {
    final adapter = _FakeAdapter((_) => (
          status: 200,
          body: {
            'lat': '41.0',
            'lon': '69.0',
            'display_name': 'Navoi Street 5, Tashkent, Uzbekistan',
            'address': {'road': 'Navoi Street', 'house_number': '5', 'city': 'Tashkent'},
          },
        ));
    final place = await _repo(adapter).reverse(41.32, 69.25);

    expect(place!.latitude, 41.32);
    expect(place.longitude, 69.25);
    expect(place.address, 'Navoi Street 5, Tashkent');
    expect(adapter.requests.single.path, '/reverse');
  });

  test('reverse returns null for an empty spot and caches that too', () async {
    final adapter =
        _FakeAdapter((_) => (status: 200, body: {'error': 'Unable to geocode'}));
    final repo = _repo(adapter);
    expect(await repo.reverse(41.0, 69.0), isNull);
    expect(await repo.reverse(41.0, 69.0), isNull);
    expect(adapter.requests, hasLength(1));
  });

  test('requests are spaced by the minimum interval', () async {
    final adapter = _FakeAdapter((_) => (status: 200, body: const []));
    final repo = _repo(adapter, minInterval: const Duration(milliseconds: 200));

    // Three different queries fired at once must still go out one by one.
    await Future.wait([repo.search('aaa'), repo.search('bbb'), repo.search('ccc')]);

    expect(adapter.times, hasLength(3));
    for (var i = 1; i < adapter.times.length; i++) {
      final gap = adapter.times[i].difference(adapter.times[i - 1]);
      expect(gap.inMilliseconds, greaterThanOrEqualTo(190));
    }
  });

  test('rate-limit responses become a friendly failure', () async {
    final adapter = _FakeAdapter((_) => (status: 429, body: const {}));
    await expectLater(
      _repo(adapter).search('amir temur'),
      throwsA(isA<GeocodingFailure>()
          .having((e) => e.message, 'message', contains('busy'))),
    );
  });

  test('a failed request does not block the ones after it', () async {
    var calls = 0;
    final adapter = _FakeAdapter((_) {
      calls++;
      return calls == 1 ? (status: 500, body: const {}) : (status: 200, body: _searchBody);
    });
    final repo = _repo(adapter);

    await expectLater(repo.search('first'), throwsA(isA<GeocodingFailure>()));
    expect(await repo.search('second'), hasLength(1));
  });
}
