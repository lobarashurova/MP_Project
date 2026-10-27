/// A delivery point chosen on the map: coordinates plus a readable address.
class DeliveryLocation {
  final double latitude;
  final double longitude;

  /// Short address for display, e.g. "Amir Temur Avenue 15, Tashkent".
  final String address;

  /// The full address as returned by the geocoder, used as a subtitle in
  /// search results. May equal [address].
  final String fullAddress;

  const DeliveryLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    String? fullAddress,
  }) : fullAddress = fullAddress ?? address;

  /// Parses one Nominatim result (search or reverse, format=jsonv2 with
  /// addressdetails=1). Returns null when the result has no coordinates.
  static DeliveryLocation? fromNominatim(Map<String, dynamic> json) {
    final lat = double.tryParse('${json['lat']}');
    final lon = double.tryParse('${json['lon']}');
    if (lat == null || lon == null) return null;

    final displayName = (json['display_name'] as String?)?.trim() ?? '';
    final details = json['address'];
    final short = details is Map
        ? shortAddress(Map<String, dynamic>.from(details), fallback: displayName)
        : _firstParts(displayName);

    return DeliveryLocation(
      latitude: lat,
      longitude: lon,
      address: short.isEmpty ? 'Unnamed location' : short,
      fullAddress: displayName.isEmpty ? short : displayName,
    );
  }

  /// Builds "street house, district, city" from Nominatim address details,
  /// skipping parts that are missing. Falls back to the first parts of
  /// [fallback] when no useful detail is present.
  static String shortAddress(Map<String, dynamic> a, {String fallback = ''}) {
    String? pick(List<String> keys) {
      for (final key in keys) {
        final value = (a[key] as String?)?.trim();
        if (value != null && value.isNotEmpty) return value;
      }
      return null;
    }

    final road = pick(['road', 'pedestrian', 'street', 'footway', 'residential']);
    final house = pick(['house_number']);
    final place = pick(['amenity', 'building', 'shop', 'office', 'tourism']);
    final area = pick(['neighbourhood', 'quarter', 'suburb', 'city_district', 'district']);
    final city = pick(['city', 'town', 'village', 'municipality', 'county', 'state']);

    final street = road == null ? null : (house == null ? road : '$road $house');

    final parts = <String>[
      if (street != null) street else if (place != null) place,
      if (area != null && street == null) area,
      if (city != null) city,
    ];

    // Drop repeats, e.g. when the district and the city share a name.
    final unique = <String>[];
    for (final part in parts) {
      if (!unique.contains(part)) unique.add(part);
    }

    return unique.isEmpty ? _firstParts(fallback) : unique.join(', ');
  }

  static String _firstParts(String displayName, {int count = 3}) {
    return displayName
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .take(count)
        .join(', ');
  }

  /// Plain-map form for storing on an order. Kept free of Firestore types so
  /// the model stays testable; the checkout converts it to a GeoPoint.
  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
      };

  @override
  bool operator ==(Object other) =>
      other is DeliveryLocation &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.address == address;

  @override
  int get hashCode => Object.hash(latitude, longitude, address);

  @override
  String toString() => 'DeliveryLocation($address @ $latitude,$longitude)';
}
