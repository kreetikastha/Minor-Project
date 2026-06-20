import '../models/band_status.dart';

class ApiService {
  // Standalone Mode: No Backend required
  // All state is managed within the app for this demonstration/UI-UX version.
  
  static bool simulateEmergency = false;

  Future<BandStatus> fetchBandStatus() async {
    // Artificial delay to simulate network latency
    await Future.delayed(const Duration(milliseconds: 500));
    
    return BandStatus(
      latitude: 27.7172,
      longitude: 85.3240,
      isEmergency: simulateEmergency,
      lastUpdated: DateTime.now(),
    );
  }

  // Method to toggle emergency state locally
  static void toggleEmergency(bool value) {
    simulateEmergency = value;
  }
}
