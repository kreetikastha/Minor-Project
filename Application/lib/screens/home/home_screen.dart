import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/band_status.dart';
import '../services/api_service.dart';
import '../services/sms_service.dart';
import '../services/contact_service.dart';
import '../services/bluetooth_service.dart';
import 'contact_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SmsService _smsService = SmsService();
  final ContactService _contactService = ContactService();
  late BandBluetoothService _bluetoothService;

  BandStatus? _currentStatus;
  Timer? _timer;
  bool _emergencyAlreadyTriggered = false;
  bool _isHardwareConnected = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _bluetoothService = BandBluetoothService(
      onEmergencyTriggered: (msg) {
        if (!_emergencyAlreadyTriggered) {
          _handleEmergency();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      onConnectionChanged: (connected) {
        setState(() => _isHardwareConnected = connected);
      },
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final status = await _apiService.fetchBandStatus();
      if (mounted) {
        if (status.isEmergency && !_emergencyAlreadyTriggered) {
          _handleEmergency();
        } else if (!status.isEmergency && _emergencyAlreadyTriggered) {
          _emergencyAlreadyTriggered = false;
          _stopAlarm();
        }
        setState(() => _currentStatus = status);
      }
    });
  }

  Future<void> _handleEmergency() async {
    _emergencyAlreadyTriggered = true;
    _startAlarm();
    if (_currentStatus != null) {
      final contacts = await _contactService.getContacts();
      if (contacts.isNotEmpty) {
        await _smsService.sendEmergencyMessages(contacts, _currentStatus!);
      }
    }
  }

  void _startAlarm() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(UrlSource('https://www.soundjay.com/buttons/beep-01a.mp3'));
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 1);
    }
  }

  void _stopAlarm() {
    _audioPlayer.stop();
    Vibration.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    _pulseController.dispose();
    _bluetoothService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEmergency = _currentStatus?.isEmergency ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Deeper Midnight Black
      body: Stack(
        children: [
          // Background Glow
          _buildBackgroundDecoration(isEmergency),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildMiniStatusHeader(isEmergency),
                      const SizedBox(height: 25),
                      _buildSectionHeader("Real-time Vitals"),
                      const SizedBox(height: 12),
                      _buildDeviceStats(),
                      const SizedBox(height: 25),
                      _buildSectionHeader("Quick Location"),
                      const SizedBox(height: 12),
                      _buildCompactLocationBar(),
                      const SizedBox(height: 25),
                      _buildSectionHeader("Safety Actions"),
                      const SizedBox(height: 12),
                      _buildActionGrid(),
                      if (isEmergency) ...[
                        const SizedBox(height: 30),
                        _buildStopAlarmButton(),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundDecoration(bool isEmergency) {
    return Positioned(
      top: -150,
      right: -100,
      child: Container(
        width: 400,
        height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: isEmergency
                ? [Colors.redAccent.withOpacity(0.2), Colors.transparent]
                : [Colors.blueAccent.withOpacity(0.15), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      centerTitle: false,
      title: const Text(
        "GUARDIAN",
        style: TextStyle(
            fontSize: 14,
            letterSpacing: 4,
            fontWeight: FontWeight.w900,
            color: Colors.blueAccent
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.history_rounded, color: Colors.white.withOpacity(0.5)),
          onPressed: () {},
        ),
        const SizedBox(width: 10),
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.white.withOpacity(0.05),
          child: const Icon(Icons.person_outline, color: Colors.white70, size: 20),
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildMiniStatusHeader(bool isEmergency) {
    final statusColor = isEmergency ? Colors.redAccent : const Color(0xFF10B981);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEmergency ? "ALERT ACTIVE" : "SYSTEM ARMED",
              style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  letterSpacing: -0.5
              ),
            ),
            Text(
              _currentStatus != null
                  ? "Last response: ${DateFormat('HH:mm:ss').format(_currentStatus!.lastUpdated)}"
                  : "Checking band connection...",
              style: const TextStyle(color: Colors.white38, fontSize: 13),
            ),
          ],
        ),
        _buildConnectionPulse(isEmergency),
      ],
    );
  }

  Widget _buildConnectionPulse(bool isEmergency) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.1).animate(_pulseController),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (isEmergency ? Colors.redAccent : Colors.blueAccent).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isHardwareConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
          color: _isHardwareConnected ? Colors.blueAccent : Colors.white24,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildDeviceStats() {
    return Row(
      children: [
        Expanded(child: _buildStatWidget(Icons.favorite, "72", "bpm", Colors.pinkAccent)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatWidget(Icons.battery_4_bar_rounded, "88", "%", Colors.greenAccent)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatWidget(Icons.sensors_rounded, "Active", "Signal", Colors.orangeAccent)),
      ],
    );
  }

  Widget _buildStatWidget(IconData icon, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // COMPACT LOCATION BAR (Small Map replacement)
  Widget _buildCompactLocationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.my_location_rounded, color: Colors.blueAccent, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _currentStatus != null
                  ? "${_currentStatus!.latitude.toStringAsFixed(5)}, ${_currentStatus!.longitude.toStringAsFixed(5)}"
                  : "Initializing tracker...",
              style: const TextStyle(color: Colors.white70, fontFamily: 'monospace', fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: () {
              if (_currentStatus != null) {
                launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=${_currentStatus!.latitude},${_currentStatus!.longitude}"));
              }
            },
            style: TextButton.styleFrom(
              backgroundColor: Colors.blueAccent.withOpacity(0.1),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(0, 32),
            ),
            child: const Text("MAP", style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildCompactAction(Icons.local_police, "POLICE", Colors.blue, () => launchUrl(Uri.parse("tel:100"))),
        _buildCompactAction(Icons.people_alt, "CONTACTS", Colors.orange, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactManagementScreen()));
        }),
        _buildCompactAction(Icons.sos_rounded, "SEND SOS", Colors.purple, () async {
          final contacts = await _contactService.getContacts();
          if (_currentStatus != null && contacts.isNotEmpty) {
            await _smsService.sendEmergencyMessages(contacts, _currentStatus!);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Alerts Dispatched")));
          }
        }),
        _buildCompactAction(Icons.medical_services, "MEDICAL", Colors.redAccent, () => launchUrl(Uri.parse("tel:102"))),
      ],
    );
  }

  Widget _buildCompactAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2),
    );
  }

  Widget _buildStopAlarmButton() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 20, spreadRadius: 5)],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 65),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: () {
          _stopAlarm();
          setState(() => ApiService.simulateEmergency = false);
        },
        child: const Text("DEACTIVATE EMERGENCY MODE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }
}