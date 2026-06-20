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
  
  BandStatus? _currentStatus;
  Timer? _timer;
  bool _emergencyAlreadyTriggered = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
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
        setState(() {
          _currentStatus = status;
        });
      }
    });
  }

  Future<void> _handleEmergency() async {
    _emergencyAlreadyTriggered = true;
    _startAlarm();
    
    // Auto-send SMS to contacts when emergency is detected
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
    Vibration.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEmergency = _currentStatus?.isEmergency ?? false;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Guardian Band", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => showModalBottomSheet(context: context, builder: (context) => _buildSettingsSheet()),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isEmergency 
              ? [Colors.red.shade900, Colors.black] 
              : [const Color(0xFF1A237E), Colors.black],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMainStatus(isEmergency),
                  const SizedBox(height: 30),
                  _buildLocationCard(),
                  const SizedBox(height: 25),
                  _buildQuickActions(),
                  const SizedBox(height: 30),
                  if (isEmergency) _buildStopAlarmButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainStatus(bool isEmergency) {
    return Column(
      children: [
        const SizedBox(height: 20),
        ScaleTransition(
          scale: Tween(begin: 1.0, end: 1.1).animate(_pulseController),
          child: Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEmergency ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
              border: Border.all(color: isEmergency ? Colors.redAccent : Colors.greenAccent, width: 2),
            ),
            child: Icon(
              isEmergency ? Icons.warning_rounded : Icons.shield_rounded,
              size: 80,
              color: isEmergency ? Colors.redAccent : Colors.greenAccent,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isEmergency ? "EMERGENCY DETECTED" : "SYSTEM SECURE",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: isEmergency ? Colors.redAccent : Colors.greenAccent,
            letterSpacing: 2,
          ),
        ),
        Text(
          _currentStatus != null 
            ? "Last sync: ${DateFormat('HH:mm:ss').format(_currentStatus!.lastUpdated)}" 
            : "Connecting to band...",
          style: const TextStyle(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.redAccent),
                const SizedBox(width: 10),
                const Text("LIVE LOCATION", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    if (_currentStatus != null) {
                      launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=${_currentStatus!.latitude},${_currentStatus!.longitude}"));
                    }
                  },
                  child: const Text("VIEW MAP"),
                ),
              ],
            ),
            const Divider(color: Colors.white10),
            const SizedBox(height: 10),
            Text(
              _currentStatus != null 
                ? "Lat: ${_currentStatus!.latitude.toStringAsFixed(4)}, Lng: ${_currentStatus!.longitude.toStringAsFixed(4)}"
                : "Fetching coordinates...",
              style: const TextStyle(fontFamily: 'monospace', color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildActionTile(Icons.phone, "Call Police", Colors.blue, () => launchUrl(Uri.parse("tel:100"))),
        _buildActionTile(Icons.people, "Contacts", Colors.orange, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ContactManagementScreen()));
        }),
        _buildActionTile(Icons.message, "Quick SMS", Colors.purple, () async {
          if (_currentStatus != null) {
            final contacts = await _contactService.getContacts();
            if (contacts.isNotEmpty) {
              await _smsService.sendEmergencyMessages(contacts, _currentStatus!);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("No emergency contacts found!"))
              );
            }
          }
        }),
        _buildActionTile(Icons.medical_services, "Ambulance", Colors.red, () => launchUrl(Uri.parse("tel:102"))),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildStopAlarmButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      onPressed: () {
        _stopAlarm();
        setState(() => ApiService.simulateEmergency = false);
      },
      icon: const Icon(Icons.stop_circle),
      label: const Text("STOP ALARM", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSettingsSheet() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(color: Color(0xFF1E1E1E), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Simulation Controls", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text("Simulate Triple Tap", style: TextStyle(color: Colors.white)),
            subtitle: const Text("Triggers SOS alert", style: TextStyle(color: Colors.white70)),
            value: ApiService.simulateEmergency,
            onChanged: (val) {
              setState(() => ApiService.simulateEmergency = val);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
