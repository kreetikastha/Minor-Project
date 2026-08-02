import 'package:flutter/material.dart';

class StopAlarmButton extends StatelessWidget {
  final VoidCallback onPressed;

  const StopAlarmButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        icon: const Icon(Icons.stop_circle, color: Colors.white),
        label: const Text(
          "STOP ALARM",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class SOSFloatingButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SOSFloatingButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: Colors.red,
      icon: const Icon(Icons.sos),
      label: const Text("SOS"),
      onPressed: onPressed,
    );
  }
}
