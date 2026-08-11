class BandStatus {
  final double? latitude;
  final double? longitude;
  final bool isEmergency;
  final DateTime lastUpdated;

  BandStatus({
    this.latitude,
    this.longitude,
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
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      isEmergency: json['is_emergency'] ?? false,
      lastUpdated: parsedDate,
    );
  }
}
