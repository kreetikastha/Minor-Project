import 'dart:async';
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
      backgroundColor: const Color(0xFF0F172A), // Modern Navy Black
      body: Stack(
        children: [
          // Background Decorative Gradients
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEmergency ? Colors.red.withOpacity(0.15) : Colors.blue.withOpacity(0.1),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 20),
                      _buildStatusCard(isEmergency),
                      const SizedBox(height: 25),
                      _buildDeviceStats(),
                      const SizedBox(height: 25),
                      _buildSectionHeader("Location Tracking"),
                      const SizedBox(height: 12),
                      _buildLocationCard(),
                      const SizedBox(height: 25),
                      _buildSectionHeader("Quick Response"),
                      const SizedBox(height: 12),
                      _buildQuickActions(),
                      if (isEmergency) ...[
                        const SizedBox(height: 30),
                        _buildStopAlarmButton(),
                      ],
                      const SizedBox(height: 40),
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

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Guardian", style: TextStyle(color: Colors.white70, fontSize: 14)),
          Text(
            "Security Dashboard",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white.withOpacity(0.9))
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              _isHardwareConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
              color: _isHardwareConnected ? Colors.blueAccent : Colors.white24,
            ),
            onPressed: () => _bluetoothService.startScan(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(bool isEmergency) {
    final statusColor = isEmergency ? Colors.redAccent : const Color(0xFF10B981);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: Tween(begin: 1.0, end: 1.15).animate(_pulseController),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(0.2),
                boxShadow: [
                  BoxShadow(color: statusColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 2)
                ],
              ),
              child: Icon(isEmergency ? Icons.warning_amber_rounded : Icons.shield_outlined,
                         color: statusColor, size: 40),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEmergency ? "CRITICAL ALERT" : "SYSTEM SECURE",
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentStatus != null
                    ? "Last sync: ${DateFormat('hh:mm:ss a').format(_currentStatus!.lastUpdated)}"
                    : "Connecting to band...",
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildStatItem(Icons.battery_charging_full, "84%", "Battery", Colors.green),
        _buildStatItem(Icons.favorite, "72 bpm", "Heart Rate", Colors.pinkAccent),
        _buildStatItem(Icons.signal_cellular_alt, "Strong", "Signal", Colors.blueAccent),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
              ),
              const SizedBox(width: 12),
              const Text("Current Coordinates", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  if (_currentStatus != null) {
                    launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=${_currentStatus!.latitude},${_currentStatus!.longitude}"));
                  }
                },
                child: const Text("MAP VIEW", style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white10)),
          Text(
            _currentStatus != null
              ? "${_currentStatus!.latitude.toStringAsFixed(6)}, ${_currentStatus!.longitude.toStringAsFixed(6)}"
              : "Locating hardware...",
            style: const TextStyle(fontFamily: 'monospace', color: Colors.white70, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.5,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildActionTile(Icons.local_police_outlined, "Police", Colors.blue, () => launchUrl(Uri.parse("tel:100"))),
        _buildActionTile(Icons.contact_phone_outlined, "Contacts", Colors.orange, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactManagementScreen()));
        }),
        _buildActionTile(Icons.send_rounded, "Send SOS", Colors.purple, () async {
          if (_currentStatus != null) {
            final contacts = await _contactService.getContacts();
            if (contacts.isNotEmpty) {
              await _smsService.sendEmergencyMessages(contacts, _currentStatus!);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Emergency Messages Sent!")));
            }
          }
        }),
        _buildActionTile(Icons.medical_information_outlined, "Ambulance", Colors.redAccent, () => launchUrl(Uri.parse("tel:102"))),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStopAlarmButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 10,
        shadowColor: Colors.redAccent.withOpacity(0.5),
      ),
      onPressed: () {
        _stopAlarm();
        setState(() => ApiService.simulateEmergency = false);
      },
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.stop_circle_outlined),
          SizedBox(width: 10),
          Text("DEACTIVATE ALARM", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }
}