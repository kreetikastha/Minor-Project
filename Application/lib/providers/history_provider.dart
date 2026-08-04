import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/history_model.dart';

class HistoryProvider with ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<SOSHistory> _history = [];

  List<SOSHistory> get history => List.unmodifiable(_history);

  String? get _uid => _auth.currentUser?.uid;

  Future<void> fetchHistory() async {
    if (_uid == null) return;

    try {
      final snapshot = await _db
          .collection('users')
          .doc(_uid)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get();

      _history = snapshot.docs.map((doc) {
        final data = doc.data();
        // Add ID if not in map
        data['id'] = doc.id;
        return SOSHistory.fromMap(data);
      }).toList();

      notifyListeners();
    } catch (e) {
      print("Error fetching history: \$e");
    }
  }

  void addEntryLocal(SOSHistory entry) {
    _history.insert(0, entry);
    notifyListeners();
  }
}
