class SOSHistory {
  final String id;
  final DateTime timestamp;
  final String locationName;
  final double latitude;
  final double longitude;
  final String status; // 'Triggered', 'SMS Sent', 'Resolved'

  SOSHistory({
    required this.id,
    required this.timestamp,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }

  factory SOSHistory.fromMap(Map<String, dynamic> map) {
    return SOSHistory(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      locationName: map['locationName'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      status: map['status'],
    );
  }
}
