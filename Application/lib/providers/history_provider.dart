import 'package:flutter/material.dart';
import '../models/history_model.dart';

class HistoryProvider with ChangeNotifier {
  final List<SOSHistory> _history = [
    SOSHistory(
      id: "1",
      timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
      locationName: "Balkumari, Lalitpur",
      latitude: 27.671,
      longitude: 85.338,
      status: "Resolved",
    ),
    SOSHistory(
      id: "2",
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      locationName: "New Baneshwor, Kathmandu",
      latitude: 27.691,
      longitude: 85.333,
      status: "SMS Sent",
    ),
  ];

  List<SOSHistory> get history => List.unmodifiable(_history);

  void addEntry(SOSHistory entry) {
    _history.insert(0, entry);
    notifyListeners();
  }
}
