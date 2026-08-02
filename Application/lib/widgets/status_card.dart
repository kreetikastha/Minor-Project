import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/band_status.dart';

class StatusCard extends StatelessWidget {
  final bool isEmergency;
  final BandStatus? status;
  final AnimationController pulseController;

  const StatusCard({
    Key? key,
    required this.isEmergency,
    required this.status,
    required this.pulseController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.05).animate(pulseController),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            colors: isEmergency
                ? [
                    Colors.red.shade700,
                    Colors.red.shade900,
                  ]
                : [
                    const Color(0xff2563EB),
                    const Color(0xff1E3A8A),
                  ],
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white.withOpacity(.15),
              child: Icon(
                isEmergency ? Icons.warning_rounded : Icons.shield_rounded,
                size: 55,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isEmergency ? "EMERGENCY DETECTED" : "SYSTEM SECURE",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              status == null
                  ? "Waiting for hardware..."
                  : "Last Sync : ${DateFormat("hh:mm:ss a").format(status!.lastUpdated)}",
              style: const TextStyle(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
