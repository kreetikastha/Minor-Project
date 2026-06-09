class BandStatus {
  final double latitude;
  final double longitude;
  final bool isEmergency;
  final DateTime lastUpdated;

  BandStatus({
    required this.latitude,
    required this.longitude,
    required this.isEmergency,
    required this.lastUpdated,
  });

  factory BandStatus.fromJson(Map<String, dynamic> json) {
    return BandStatus(
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      isEmergency: json['is_emergency'] ?? false,
      lastUpdated: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
