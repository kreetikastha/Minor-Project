import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationProvider with ChangeNotifier {
  final List<SystemNotification> _notifications = [
    SystemNotification(
      id: "1",
      title: "System Ready",
      message: "Guardian Band successfully connected via Bluetooth.",
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      type: "System",
    ),
    SystemNotification(
      id: "2",
      title: "Battery Low",
      message: "Band battery is below 20%. Please charge soon.",
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      type: "Battery",
    ),
  ];

  List<SystemNotification> get notifications => List.unmodifiable(_notifications);

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}
