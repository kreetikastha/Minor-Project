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

  // Register New User
  Future<bool> register(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;
      if (user != null) {
        // Initialize user profile in Firestore
        await _db.collection('users').doc(user.uid).set({
          'email': email,
          'name': 'User',
          'blood_group': 'Unknown',
          'phone': '',
          'address': '',
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      return true;
    } catch (e) {
      print("Firebase Registration Error: $e");
      return false;
    }
  }

  // Stream for Real-time Status Updates
  Stream<BandStatus> getStatusStream() {
    return _db.collection('bands').doc('guardian_device_01').snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return BandStatus.fromJson(doc.data()!);
      }
      return BandStatus(
        latitude: 27.7172,
        longitude: 85.3240,
        isEmergency: simulateEmergency,
        lastUpdated: DateTime.now(),
      );
    });
  }

  // Fetch Latest Status from Firestore
  Future<BandStatus> fetchBandStatus() async {
    try {
      if (simulateEmergency) {
        return BandStatus(
          latitude: 27.7172,
          longitude: 85.3240,
          isEmergency: true,
          lastUpdated: DateTime.now(),
        );
      }

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

  // Send SOS Alert to Firestore and log history
  Future<void> sendAlertToBackend(String deviceId, double lat, double lng, {String? locationName}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final now = DateTime.now();

      // 1. Log to Global Alerts
      await _db.collection('alerts').add({
        'deviceId': deviceId,
        'userId': user.uid,
        'latitude': lat,
        'longitude': lng,
        'status': 'Emergency',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      // 2. Update current Device Status
      await _db.collection('bands').doc('guardian_device_01').set({
        'latitude': lat,
        'longitude': lng,
        'is_emergency': true,
        'updated_at': now.toIso8601String(),
      }, SetOptions(merge: true));

      // 3. Log to User's Personal History
      await _db.collection('users').doc(user.uid).collection('history').add({
        'timestamp': now.toIso8601String(),
        'locationName': locationName ?? "Current Location",
        'latitude': lat,
        'longitude': lng,
        'status': 'SOS Triggered',
      });
      
      print("Alert and history synced with Firebase");
    } catch (e) {
      print("Error sending alert to Firebase: $e");
    }
  }

  // Sign Out
  Future<void> logout() async {
    await _auth.signOut();
  }
}
