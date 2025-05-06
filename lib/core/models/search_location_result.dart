class SearchLocationResult {
  final String name;
  final String placeId;
  final double latitude;
  final double longitude;
  final String? formattedAddress;
  final String? administrativeArea;
  final String? country;

  SearchLocationResult({
    required this.name,
    required this.placeId,
    required this.latitude,
    required this.longitude,
    this.formattedAddress,
    this.administrativeArea,
    this.country,
  });

  factory SearchLocationResult.fromJson(Map<String, dynamic> json) {
    return SearchLocationResult(
      name: json['name'] as String,
      placeId: json['place_id'] as String,
      latitude: (json['geometry']['location']['lat'] as num).toDouble(),
      longitude: (json['geometry']['location']['lng'] as num).toDouble(),
      formattedAddress: json['formatted_address'] as String?,
      administrativeArea: json['administrative_area'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'place_id': placeId,
      'latitude': latitude,
      'longitude': longitude,
      'formatted_address': formattedAddress,
      'administrative_area': administrativeArea,
      'country': country,
    };
  }
} 