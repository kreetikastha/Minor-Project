import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _profile;
  bool _isLoading = false;

  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  String? get uid => _auth.currentUser?.uid;

  void clear() {
    _profile = null;
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    if (uid == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _profile = doc.data();
      } else {
        // Initialize if not exists
        _profile = {
          'name': 'Guardian User',
          'email': _auth.currentUser?.email,
          'phone': '',
          'address': '',
          'blood_group': '--',
          'allergies': 'None',
          'medical_notes': 'N/A'
        };
        await _db.collection('users').doc(uid).set(_profile!);
      }
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print("Error fetching profile: \$e");
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    required String name,
    required String phone,
    required String address,
    required String bloodGroup,
    required String allergies,
    required String medicalNotes,
  }) async {
    if (uid == null) return;

    try {
      final data = {
        'name': name,
        'phone': phone,
        'address': address,
        'blood_group': bloodGroup,
        'allergies': allergies,
        'medical_notes': medicalNotes,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _db.collection('users').doc(uid).update(data);
      _profile?.addAll(data);
      notifyListeners();
    } catch (e) {
      print("Error updating profile: \$e");
      rethrow;
    }
  }
}
