class PlaceDetail {
  final String placeId;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  const PlaceDetail({
    required this.placeId,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });

  factory PlaceDetail.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>? ?? {};
    final location = geometry['location'] as Map<String, dynamic>? ?? {};
    return PlaceDetail(
      placeId: json['place_id'] as String? ?? '',
      formattedAddress: json['formatted_address'] as String? ?? '',
      latitude: (location['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (location['lng'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
