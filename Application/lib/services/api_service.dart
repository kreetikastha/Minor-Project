import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/band_status.dart';

class ApiService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  static bool simulateEmergency = false;

  // Firebase Authentication
  Future<bool> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      print("Firebase Login Error: $e");
      return false;
    }
  }

  // Register New User (Optional)
  Future<bool> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return true;
    } catch (e) {
      print("Firebase Registration Error: $e");
      return false;
    }
  }

  // Fetch Latest Status from Firestore
  Future<BandStatus> fetchBandStatus() async {
    try {
      // In simulation mode, return hardcoded data
      if (simulateEmergency) {
        return BandStatus(
          latitude: 27.7172,
          longitude: 85.3240,
          isEmergency: true,
          lastUpdated: DateTime.now(),
        );
      }

      // Real Mode: Get from Firestore collection 'bands'
      var doc = await _db.collection('bands').doc('guardian_device_01').get();
      
      if (doc.exists) {
        return BandStatus.fromJson(doc.data()!);
      } else {
        return BandStatus(
          latitude: 27.7172,
          longitude: 85.3240,
          isEmergency: false,
          lastUpdated: DateTime.now(),
        );
      }
    } catch (e) {
      print("Firestore Error: $e");
      return BandStatus(
        latitude: 27.7172,
        longitude: 85.3240,
        isEmergency: false,
        lastUpdated: DateTime.now(),
      );
    }
  }

  // Send SOS Alert to Firestore
  Future<void> sendAlertToBackend(String deviceId, double lat, double lng) async {
    try {
      await _db.collection('alerts').add({
        'deviceId': deviceId,
        'latitude': lat,
        'longitude': lng,
        'status': 'Emergency',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // Also update the band's current status
      await _db.collection('bands').doc('guardian_device_01').set({
        'latitude': lat,
        'longitude': lng,
        'is_emergency': true,
        'updated_at': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      
      print("Alert synced with Firebase Firestore");
    } catch (e) {
      print("Error sending alert to Firebase: $e");
    }
  }

  // Sign Out
  Future<void> logout() async {
    await _auth.signOut();
  }
}
