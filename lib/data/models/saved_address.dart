import 'dart:convert';

import 'package:xurmo/data/models/delivery_location.dart';

/// One address the customer has kept so checkout can be a single tap next
/// time: the text that goes on the order, the map pin behind it, and the
/// phone number they used with it.
class SavedAddress {
  /// Labels offered when saving. The customer can still type their own.
  static const List<String> labelSuggestions = ['Home', 'Work', 'Other'];

  final String id;

  /// What the customer calls this place, e.g. "Home".
  final String label;

  /// The address exactly as it goes on the order, apartment and entrance
  /// included — not just the geocoder's street line.
  final String address;

  /// Map pin, when the address was picked on the map. Null for typed-only
  /// addresses, which are still perfectly usable.
  final double? latitude;
  final double? longitude;

  final String phone;

  /// Milliseconds since epoch, bumped every time the address is used. The
  /// list is kept newest-first so the place they order to most sits first.
  final int lastUsedAt;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.lastUsedAt,
    this.latitude,
    this.longitude,
    this.phone = '',
  });

  bool get hasPin => latitude != null && longitude != null;

  /// The pin to reopen the map on, or null when this address was typed.
  DeliveryLocation? get location => hasPin
      ? DeliveryLocation(
          latitude: latitude!,
          longitude: longitude!,
          address: address,
        )
      : null;

  /// Used to spot "the same address saved twice" when the customer only
  /// changed spacing or case.
  static String normalize(String address) =>
      address.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  String get key => normalize(address);

  SavedAddress copyWith({
    String? label,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    int? lastUsedAt,
  }) {
    return SavedAddress(
      id: id,
      label: label ?? this.label,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'address': address,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        'phone': phone,
        'lastUsedAt': lastUsedAt,
      };

  /// Returns null for an entry that lost its id or address, so one bad row
  /// from an older build can be dropped instead of breaking the whole list.
  static SavedAddress? fromJson(Map<String, dynamic> json) {
    final id = (json['id'] as String?)?.trim() ?? '';
    final address = (json['address'] as String?)?.trim() ?? '';
    if (id.isEmpty || address.isEmpty) return null;

    return SavedAddress(
      id: id,
      label: (json['label'] as String?)?.trim().isNotEmpty == true
          ? (json['label'] as String).trim()
          : 'Address',
      address: address,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phone: (json['phone'] as String?)?.trim() ?? '',
      lastUsedAt: (json['lastUsedAt'] as num?)?.toInt() ?? 0,
    );
  }

  /// Decodes the stored list, skipping anything unreadable. A corrupt store
  /// reads as "no saved addresses" rather than a crash on the checkout.
  static List<SavedAddress> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .whereType<SavedAddress>()
          .toList();
    } on FormatException {
      return const [];
    }
  }

  static String encode(List<SavedAddress> addresses) =>
      jsonEncode(addresses.map((a) => a.toJson()).toList());

  @override
  bool operator ==(Object other) =>
      other is SavedAddress &&
      other.id == id &&
      other.label == label &&
      other.address == address &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.phone == phone &&
      other.lastUsedAt == lastUsedAt;

  @override
  int get hashCode =>
      Object.hash(id, label, address, latitude, longitude, phone, lastUsedAt);

  @override
  String toString() => 'SavedAddress($label: $address)';
}
