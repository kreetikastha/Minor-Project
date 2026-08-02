import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/notification_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      appBar: AppBar(
        title: const Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () => context.read<NotificationProvider>().clearAll(),
            child: const Text("Clear All", style: TextStyle(color: Colors.blue)),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.notifications.isEmpty) {
            return const Center(
              child: Text("No notifications", style: TextStyle(color: Colors.white54)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: provider.notifications.length,
            itemBuilder: (context, index) {
              final note = provider.notifications[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                decoration: BoxDecoration(
                  color: note.isRead ? const Color(0xff1E293B) : const Color(0xff2D3748),
                  borderRadius: BorderRadius.circular(20),
                  border: note.isRead ? null : Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: ListTile(
                  onTap: () => provider.markAsRead(note.id),
                  leading: CircleAvatar(
                    backgroundColor: _getTypeColor(note.type).withOpacity(0.1),
                    child: Icon(_getTypeIcon(note.type), color: _getTypeColor(note.type)),
                  ),
                  title: Text(note.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Text(note.message, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('hh:mm a').format(note.timestamp),
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'SOS': return Icons.warning_rounded;
      case 'Battery': return Icons.battery_alert_rounded;
      default: return Icons.info_outline_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'SOS': return Colors.red;
      case 'Battery': return Colors.orange;
      default: return Colors.blue;
    }
  }
}
