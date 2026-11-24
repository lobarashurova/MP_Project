import 'package:shared_preferences/shared_preferences.dart';
import 'package:xurmo/data/models/saved_address.dart';

/// Stores the customer's delivery addresses on the device.
///
/// SharedPreferences rather than Firestore on purpose: the checkout needs the
/// list before the first frame and offline, and an address is only useful on
/// the phone the order is placed from. Every method returns the list as it
/// stands after the change, so callers can drop it straight into setState.
class SavedAddressRepository {
  static const String storageKey = 'saved_addresses_v1';

  /// Keeps the picker scannable and the stored blob small.
  static const int maxAddresses = 8;

  final SharedPreferences? _injected;

  /// Pass [prefs] in tests; production code lets it resolve lazily.
  SavedAddressRepository({SharedPreferences? prefs}) : _injected = prefs;

  Future<SharedPreferences> get _prefs async =>
      _injected ?? await SharedPreferences.getInstance();

  Future<List<SavedAddress>> load() async {
    final prefs = await _prefs;
    return _sorted(SavedAddress.decode(prefs.getString(storageKey)));
  }

  /// Adds [address], or updates the existing entry when the same place is
  /// saved again — matched on id first, then on the address text, so saving
  /// "Home" twice renames instead of duplicating.
  Future<List<SavedAddress>> save(SavedAddress address) async {
    final current = await load();
    final kept = current
        .where((a) => a.id != address.id && a.key != address.key)
        .toList();
    return _write([address, ...kept]);
  }

  Future<List<SavedAddress>> remove(String id) async {
    final current = await load();
    return _write(current.where((a) => a.id != id).toList());
  }

  /// Moves an address to the front of the list after it is used.
  Future<List<SavedAddress>> touch(String id, {required int usedAt}) async {
    final current = await load();
    final index = current.indexWhere((a) => a.id == id);
    if (index == -1) return current;

    final updated = current[index].copyWith(lastUsedAt: usedAt);
    return _write([
      updated,
      ...current.where((a) => a.id != id),
    ]);
  }

  Future<List<SavedAddress>> clear() async {
    final prefs = await _prefs;
    await prefs.remove(storageKey);
    return const [];
  }

  Future<List<SavedAddress>> _write(List<SavedAddress> addresses) async {
    final trimmed = _sorted(addresses).take(maxAddresses).toList();
    final prefs = await _prefs;
    await prefs.setString(storageKey, SavedAddress.encode(trimmed));
    return trimmed;
  }

  /// Most recently used first; the oldest entries are the ones dropped once
  /// the list is full.
  static List<SavedAddress> _sorted(List<SavedAddress> addresses) {
    final copy = [...addresses]
      ..sort((a, b) => b.lastUsedAt.compareTo(a.lastUsedAt));
    return copy;
  }
}
