class PlaceRef {
  const PlaceRef({
    required this.name,
    this.latitude,
    this.longitude,
    this.placeId,
    this.address,
    this.mapsUrl,
  });

  final String name;
  final double? latitude;
  final double? longitude;
  final String? placeId;
  final String? address;
  final String? mapsUrl;

  Map<String, dynamic> toMap() => {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'placeId': placeId,
    'address': address,
    'mapsUrl': mapsUrl,
  };

  factory PlaceRef.fromMap(Map<String, dynamic> m) => PlaceRef(
    name: m['name'] as String? ?? '',
    latitude: (m['latitude'] as num?)?.toDouble(),
    longitude: (m['longitude'] as num?)?.toDouble(),
    placeId: m['placeId'] as String?,
    address: m['address'] as String?,
    mapsUrl: m['mapsUrl'] as String?,
  );
}
