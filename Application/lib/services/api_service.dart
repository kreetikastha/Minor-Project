import '../models/band_status.dart';

class ApiService {
  // Replace with your actual backend URL
  // The SIM-based band will post its GPS and tap status here
  static const String baseUrl = 'https://your-backend-api.com/api';

  // Simulation flag for testing the UI
  static bool simulateEmergency = false;

  Future<BandStatus> fetchBandStatus() async {
    // In production:
    // final response = await http.get(Uri.parse('$baseUrl/status'));
    // return BandStatus.fromJson(jsonDecode(response.body));

    await Future.delayed(const Duration(milliseconds: 800));
    return BandStatus(
      latitude: 27.7172,
      longitude: 85.3240,
      isEmergency: simulateEmergency,
      lastUpdated: DateTime.now(),
    );
  }
}
