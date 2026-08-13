import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/band_status.dart';

class ApiService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  
  static bool simulateEmergency = false;

  String? get currentUserEmail => _auth.currentUser?.email;

  // Firebase Authentication
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async => await _auth.signOut();

  // Band Data Methods
  Future<BandStatus> fetchBandStatus() async {
    final bandId = await getAssignedBandId();
    final snapshot = await _rtdb.ref('bands/$bandId').get();
    if (snapshot.exists && snapshot.value != null) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
      return BandStatus.fromJson(data);
    }
    return BandStatus(
      latitude: 27.6713,
      longitude: 85.3392,
      googleMapsLink: "",
      isEmergency: false,
      lastUpdated: DateTime.now(),
    );
  }

  Stream<BandStatus> getStatusStream(String bandId) {
    return _rtdb.ref('bands/$bandId').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return BandStatus.fromJson(data);
      }
      return BandStatus(
        latitude: 27.6713,
        longitude: 85.3392,
        googleMapsLink: "",
        isEmergency: simulateEmergency,
        lastUpdated: DateTime.now(),
      );
    });
  }

  Future<void> deactivateEmergency(String bandId) async {
    final user = _auth.currentUser;
    try {
      await _rtdb.ref('bands/$bandId').update({
        'is_emergency': false,
        'stop_alarm_request': true,
      });

      if (user != null) {
        await _db.collection('users').doc(user.uid).collection('history').add({
          'timestamp': FieldValue.serverTimestamp(),
          'event': 'SOS Acknowledged',
          'status': 'Safe',
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<bool> linkBandToUser(String bandId) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await _db.collection('users').doc(user.uid).set({
        'assigned_band_id': bandId,
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String> getAssignedBandId() async {
    final user = _auth.currentUser;
    if (user == null) return 'guardian_device_01';
    var doc = await _db.collection('users').doc(user.uid).get();
    return doc.data()?['assigned_band_id'] as String? ?? 'guardian_device_01';
  }

  Future<void> logSOS(BandStatus status, String address) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _db.collection('users').doc(user.uid).collection('history').add({
        'timestamp': FieldValue.serverTimestamp(),
        'latitude': status.latitude,
        'longitude': status.longitude,
        'address': address,
        'google_maps_link': status.googleMapsLink,
        'event_type': 'Vibration Alert',
      });
    } catch (e) {
      print("DEBUG: Logging failed: $e");
    }
  }
}
