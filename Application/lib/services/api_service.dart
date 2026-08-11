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

  // Stream for Real-time Status Updates
  Stream<BandStatus> getStatusStream(String bandId) {
    return _rtdb.ref('bands/$bandId').onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(event.snapshot.value as Map);
        return BandStatus.fromJson(data);
      }
      return BandStatus(
        latitude: 27.6713,
        longitude: 85.3392,
        isEmergency: simulateEmergency,
        lastUpdated: DateTime.now(),
      );
    });
  }

  // Remote Deactivation
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

  Future<void> logout() async => await _auth.signOut();
}
