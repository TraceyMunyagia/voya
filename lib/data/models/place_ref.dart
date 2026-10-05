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

  Map<String, dynamic> toJson() => {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'place_id': placeId,
    'address': address,
    'maps_url': mapsUrl,
  };

  factory PlaceRef.fromJson(Map<String, dynamic> m) => PlaceRef(
    name: m['name'] as String? ?? '',
    latitude: (m['latitude'] as num?)?.toDouble(),
    longitude: (m['longitude'] as num?)?.toDouble(),
    placeId: m['place_id'] as String?,
    address: m['address'] as String?,
    mapsUrl: m['maps_url'] as String?,
  );
}
