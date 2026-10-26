import 'package:flutter_test/flutter_test.dart';
import 'package:xurmo/data/models/delivery_location.dart';

void main() {
  group('DeliveryLocation.shortAddress', () {
    test('uses street and house number with the city', () {
      expect(
        DeliveryLocation.shortAddress({
          'road': 'Amir Temur Avenue',
          'house_number': '15',
          'suburb': 'Yunusabad',
          'city': 'Tashkent',
        }),
        'Amir Temur Avenue 15, Tashkent',
      );
    });

    test('uses the street alone when there is no house number', () {
      expect(
        DeliveryLocation.shortAddress({'road': 'Navoi Street', 'city': 'Tashkent'}),
        'Navoi Street, Tashkent',
      );
    });

    test('falls back to a named place and district when there is no street', () {
      expect(
        DeliveryLocation.shortAddress({
          'amenity': 'Chorsu Bazaar',
          'suburb': 'Shaykhontohur',
          'city': 'Tashkent',
        }),
        'Chorsu Bazaar, Shaykhontohur, Tashkent',
      );
    });

    test('does not repeat a district that shares the city name', () {
      expect(
        DeliveryLocation.shortAddress({'district': 'Tashkent', 'city': 'Tashkent'}),
        'Tashkent',
      );
    });

    test('falls back to the first parts of the display name', () {
      expect(
        DeliveryLocation.shortAddress({}, fallback: 'A, B, C, D, E'),
        'A, B, C',
      );
    });
  });

  group('DeliveryLocation.fromNominatim', () {
    test('parses string coordinates and address details', () {
      final place = DeliveryLocation.fromNominatim({
        'lat': '41.3111',
        'lon': '69.2797',
        'display_name': 'Amir Temur Square, Tashkent, Uzbekistan',
        'address': {'road': 'Amir Temur Avenue', 'city': 'Tashkent'},
      })!;
      expect(place.latitude, 41.3111);
      expect(place.longitude, 69.2797);
      expect(place.address, 'Amir Temur Avenue, Tashkent');
      expect(place.fullAddress, 'Amir Temur Square, Tashkent, Uzbekistan');
    });

    test('returns null without coordinates', () {
      expect(DeliveryLocation.fromNominatim({'display_name': 'Nowhere'}), isNull);
      expect(DeliveryLocation.fromNominatim({'lat': 'x', 'lon': '1'}), isNull);
    });

    test('never produces an empty address', () {
      final place = DeliveryLocation.fromNominatim({'lat': '1', 'lon': '2'})!;
      expect(place.address, isNotEmpty);
    });
  });

  test('toMap stores coordinates and the address', () {
    const place = DeliveryLocation(latitude: 41.3, longitude: 69.2, address: 'Home');
    expect(place.toMap(), {'latitude': 41.3, 'longitude': 69.2, 'address': 'Home'});
    expect(place.fullAddress, 'Home');
  });
}
