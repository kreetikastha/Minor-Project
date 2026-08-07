import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart'; // NEW
import '../models/band_status.dart';

class ApiService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance; // NEW
  
  static bool simulateEmergency = false;

  // Firebase Authentication - Login
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'No user found for that email.';
      if (e.code == 'wrong-password') return 'Wrong password provided.';
      if (e.code == 'invalid-email') return 'The email address is badly formatted.';
      return e.message ?? 'An unknown error occurred.';
    } catch (e) {
      return e.toString();
    }
  }

  // Firebase Authentication - Register
  Future<String?> register(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = userCredential.user;
      if (user != null) {
        // Initialize user profile in Firestore
        await _db.collection('users').doc(user.uid).set({
          'email': email,
          'name': 'Guardian User',
          'blood_group': 'Unknown',
          'phone': '',
          'address': '',
          'created_at': FieldValue.serverTimestamp(),
        });
      }
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') return 'The password provided is too weak.';
      if (e.code == 'email-already-in-use') return 'An account already exists for that email.';
      if (e.code == 'invalid-email') return 'The email address is badly formatted.';
      return e.message ?? 'An unknown error occurred.';
    } catch (e) {
      return e.toString();
    }
  }

  // Firebase Authentication - Reset Password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'No user found for that email.';
      if (e.code == 'invalid-email') return 'The email address is badly formatted.';
      return e.message ?? 'An unknown error occurred.';
    } catch (e) {
      return e.toString();
    }
  }

  // Link a physical band to the current user
  Future<bool> linkBandToUser(String bandId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print("DEBUG: LINK FAILED - No user is currently logged in.");
        return false;
      }
      
      print("DEBUG: Attempting to link band $bandId to user ${user.uid}");
      
      await _db.collection('users').doc(user.uid).set({
        'assigned_band_id': bandId,
      }, SetOptions(merge: true));
      
      print("DEBUG: LINK SUCCESS - Band ID saved to Firestore.");
      return true;
    } catch (e) {
      print("DEBUG: FIREBASE ERROR - $e");
      return false;
    }
  }

  // Get the assigned band ID for the current user
  Future<String> getAssignedBandId() async {
    final user = _auth.currentUser;
    if (user == null) return 'guardian_device_01'; // Default fallback
    
    var doc = await _db.collection('users').doc(user.uid).get();
    return doc.data()?['assigned_band_id'] as String? ?? 'guardian_device_01';
  }

  // Updated Stream: Listens to the Realtime Database (RTDB)
  Stream<BandStatus> getStatusStream(String bandId) {
    // If the user types 'guardian_device_01', we listen to 'bands/guardian_device_01'
    return _rtdb.ref('bands/$bandId').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return BandStatus.fromJson(data);
      }
      return BandStatus(
        latitude: 27.7172,
        longitude: 85.3240,
        isEmergency: simulateEmergency,
        lastUpdated: DateTime.now(),
      );
    });
  }

  // Remote Deactivation: Tells the hardware to stop the alarm
  Future<void> deactivateEmergency(String bandId) async {
    await _rtdb.ref('bands/$bandId').update({
      'is_emergency': false,
      'stop_alarm_request': true,
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
      print("Firestore Error: \$e");
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
      print("Error sending alert to Firebase: \$e");
    }
  }

  // Sign Out
  Future<void> logout() async {
    await _auth.signOut();
  }
}
