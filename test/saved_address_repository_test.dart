import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xurmo/data/models/saved_address.dart';
import 'package:xurmo/data/repositories/saved_address_repository.dart';

SavedAddress address({
  required String id,
  String label = 'Home',
  String text = 'Amir Temur Avenue 15, Tashkent',
  int usedAt = 1,
  double? latitude,
  double? longitude,
  String phone = '',
}) {
  return SavedAddress(
    id: id,
    label: label,
    address: text,
    lastUsedAt: usedAt,
    latitude: latitude,
    longitude: longitude,
    phone: phone,
  );
}

void main() {
  late SharedPreferences prefs;
  late SavedAddressRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = SavedAddressRepository(prefs: prefs);
  });

  group('SavedAddressRepository', () {
    test('starts empty and keeps what it saves', () async {
      expect(await repo.load(), isEmpty);

      final saved = await repo.save(address(id: '1'));

      expect(saved.single.label, 'Home');
      expect(await repo.load(), saved);
    });

    test('lists the most recently used address first', () async {
      await repo.save(address(id: '1', text: 'Street 1', usedAt: 10));
      await repo.save(address(id: '2', text: 'Street 2', usedAt: 30));
      await repo.save(address(id: '3', text: 'Street 3', usedAt: 20));

      expect((await repo.load()).map((a) => a.id), ['2', '3', '1']);
    });

    test('saving the same address again replaces it instead of duplicating',
        () async {
      await repo.save(address(id: '1', text: 'Mustaqillik 7', usedAt: 1));
      final saved = await repo.save(
        address(id: '2', label: 'Work', text: '  mustaqillik   7 ', usedAt: 2),
      );

      expect(saved, hasLength(1));
      expect(saved.single.label, 'Work');
    });

    test('touch bumps an address to the front', () async {
      await repo.save(address(id: '1', text: 'Street 1', usedAt: 10));
      await repo.save(address(id: '2', text: 'Street 2', usedAt: 30));

      final bumped = await repo.touch('1', usedAt: 99);

      expect(bumped.first.id, '1');
      expect(bumped.first.lastUsedAt, 99);
    });

    test('touch on an unknown id leaves the list alone', () async {
      await repo.save(address(id: '1'));
      expect(await repo.touch('nope', usedAt: 50), await repo.load());
    });

    test('remove drops only the one address', () async {
      await repo.save(address(id: '1', text: 'Street 1'));
      await repo.save(address(id: '2', text: 'Street 2', usedAt: 2));

      final left = await repo.remove('1');

      expect(left.map((a) => a.id), ['2']);
      expect(await repo.load(), left);
    });

    test('drops the oldest once the list is full', () async {
      for (var i = 0; i < SavedAddressRepository.maxAddresses + 3; i++) {
        await repo.save(address(id: '$i', text: 'Street $i', usedAt: i));
      }

      final saved = await repo.load();
      expect(saved, hasLength(SavedAddressRepository.maxAddresses));
      expect(saved.first.id, '${SavedAddressRepository.maxAddresses + 2}');
      expect(saved.map((a) => a.id), isNot(contains('0')));
    });

    test('a map pin survives the round trip', () async {
      await repo.save(address(
        id: '1',
        latitude: 41.311,
        longitude: 69.279,
        phone: '+998901234567',
      ));

      final loaded = (await repo.load()).single;

      expect(loaded.hasPin, isTrue);
      expect(loaded.location?.latitude, 41.311);
      expect(loaded.location?.address, loaded.address);
      expect(loaded.phone, '+998901234567');
    });

    test('a typed address has no pin', () async {
      await repo.save(address(id: '1'));
      final loaded = (await repo.load()).single;

      expect(loaded.hasPin, isFalse);
      expect(loaded.location, isNull);
    });

    test('corrupt storage reads as no saved addresses', () async {
      await prefs.setString(SavedAddressRepository.storageKey, 'not json');
      expect(await repo.load(), isEmpty);
    });

    test('an entry without an address is skipped', () async {
      await prefs.setString(
        SavedAddressRepository.storageKey,
        '[{"id":"1","label":"Home"},{"id":"2","label":"Work",'
            '"address":"Street 2","lastUsedAt":5}]',
      );

      expect((await repo.load()).map((a) => a.id), ['2']);
    });

    test('clear empties the store', () async {
      await repo.save(address(id: '1'));
      expect(await repo.clear(), isEmpty);
      expect(await repo.load(), isEmpty);
    });
  });
}
