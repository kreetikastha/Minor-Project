import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/band_status.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, local IP for physical devices
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  
  static bool simulateEmergency = false;

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Login API Error: $e");
      return false;
    }
  }

  Future<BandStatus> fetchBandStatus() async {
    try {
      // Simulation for now
      return BandStatus(
        latitude: 27.7172,
        longitude: 85.3240,
        isEmergency: simulateEmergency,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      print("API Error: $e");
      throw e;
    }
  }

  Future<void> sendAlertToBackend(String deviceId, double lat, double lng) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/alerts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': deviceId,
          'latitude': lat,
          'longitude': lng,
          'status': 'Emergency',
        }),
      );

      if (response.statusCode == 201) {
        print("Alert synced with backend");
      }
    } catch (e) {
      print("Error sending alert: $e");
    }
  }
}
