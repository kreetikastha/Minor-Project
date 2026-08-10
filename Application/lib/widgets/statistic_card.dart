import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/band_provider.dart';

class StatisticsGrid extends StatelessWidget {
  final bool hardwareConnected;
  final bool isEmergency;
  final bool hasStatus;

  const StatisticsGrid({
    Key? key,
    required this.hardwareConnected,
    required this.isEmergency,
    required this.hasStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<BandProvider>(
      builder: (context, band, child) {
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.4,
          children: [
            _StatCard(
              icon: Icons.cloud_done_rounded,
              title: "Cloud Sync",
              value: hardwareConnected ? "Online" : "Offline",
              color: hardwareConnected ? Colors.greenAccent : Colors.redAccent,
            ),
            _StatCard(
              icon: Icons.gps_fixed,
              title: "GPS",
              value: hasStatus ? "Active" : "Searching...",
              color: hasStatus ? Colors.green : Colors.orange,
            ),
            _StatCard(
              icon: Icons.signal_cellular_alt_rounded,
              title: "GSM",
              value: band.gsmStatus,
              color: band.gsmStatus == "Ready" ? Colors.green : Colors.red,
            ),
            _StatCard(
              icon: _getBatteryIcon(band.batteryLevel),
              title: "Battery",
              value: "${band.batteryLevel}%",
              color: _getBatteryColor(band.batteryLevel),
            ),
          ],
        );
      },
    );
  }

  IconData _getBatteryIcon(int level) {
    if (level > 80) return Icons.battery_full_rounded;
    if (level > 50) return Icons.battery_5_bar_rounded;
    if (level > 20) return Icons.battery_2_bar_rounded;
    return Icons.battery_alert_rounded;
  }

  Color _getBatteryColor(int level) {
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff1E293B),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
