class BandStatus {
  final double latitude;
  final double longitude;
  final String googleMapsLink;
  final bool isEmergency;
  final DateTime lastUpdated;

  BandStatus({
    required this.latitude,
    required this.longitude,
    required this.googleMapsLink,
    required this.isEmergency,
    required this.lastUpdated,
  });

  factory BandStatus.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    try {
      if (json['updated_at'] is int) {
        parsedDate = DateTime.fromMillisecondsSinceEpoch(json['updated_at']);
      } else if (json['updated_at'] is String) {
        parsedDate = DateTime.parse(json['updated_at']);
      } else {
        parsedDate = DateTime.now();
      }
    } catch (e) {
      parsedDate = DateTime.now();
    }

    return BandStatus(
      latitude: json['latitude']?.toDouble() ?? 27.6713,
      longitude: json['longitude']?.toDouble() ?? 85.3392,
      googleMapsLink: json['google_maps_link'] ?? "https://www.google.com/maps?q=${json['latitude']},${json['longitude']}",
      isEmergency: json['is_emergency'] ?? false,
      lastUpdated: parsedDate,
    );
  }
}
