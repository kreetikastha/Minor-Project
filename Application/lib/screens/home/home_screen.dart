import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:geocoding/geocoding.dart';
import '../../models/band_status.dart';
import '../../services/api_service.dart';
import '../../services/sms_service.dart';
import '../../services/contact_service.dart';
import '../../services/bluetooth_service.dart';
import '../../services/notification_service.dart';
import '../contacts/contact_screen.dart';

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

  final NotificationService _notificationService = NotificationService();
  BandStatus? _currentStatus;
  StreamSubscription<BandStatus>? _statusSubscription;
  String _assignedBandId = 'guardian_device_01';
  String _currentAddress = "Locating...";
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
    
    _setupBandListener();
  }

  Future<void> _setupBandListener() async {
    // 1. Get the real band ID assigned to this user
    final bandId = await _apiService.getAssignedBandId();
    setState(() => _assignedBandId = bandId);

    // 2. Start real-time listener for that specific band
    _statusSubscription?.cancel();
    _statusSubscription = _apiService.getStatusStream(bandId).listen((status) {
      if (mounted) {
        if (status.isEmergency && !_emergencyAlreadyTriggered) {
          _handleEmergency();
        } else if (!status.isEmergency && _emergencyAlreadyTriggered) {
          _emergencyAlreadyTriggered = false;
          _stopAlarm();
        }
        setState(() => _currentStatus = status);
        _updateAddress(status.latitude, status.longitude);
      }
    });
  }

  Future<void> _updateAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = "${place.name}, ${place.subLocality}, ${place.locality}";
        });
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
    }
  }

  Future<void> _handleEmergency() async {
    _emergencyAlreadyTriggered = true;
    _startAlarm();
    
    // Show high-priority local notification
    await _notificationService.showEmergencyNotification(address: _currentAddress);

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
    
    final hasVibrator = await Vibration.hasVibrator();
    if (hasVibrator == true) {
      Vibration.vibrate(pattern: [500, 1000, 500, 1000], repeat: 1);
    }
  }

  void _stopAlarm() {
    _audioPlayer.stop();
    Vibration.cancel();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
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
        IconButton(
          icon: Icon(Icons.add_link_rounded, color: Colors.blueAccent.withOpacity(0.7)),
          onPressed: () => _showLinkBandDialog(),
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
        Expanded(
          child: Column(
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(child: _buildStatWidget(Icons.favorite, "72", "bpm", Colors.pinkAccent)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatWidget(Icons.battery_4_bar_rounded, "88", "%", Colors.greenAccent)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatWidget(Icons.sensors_rounded, "Active", "Signal", Colors.orangeAccent)),
          ],
        );
      }
    );
  }

  Widget _buildStatWidget(IconData icon, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 2),
                Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // COMPACT MINI-MAP (Professional Tracker)
  Widget _buildCompactLocationBar() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Radar/Grid Background
            CustomPaint(
              size: Size.infinite,
              painter: GridPainter(),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radar_rounded, color: Colors.blueAccent.withOpacity(0.2), size: 40),
                  const SizedBox(height: 8),
                  Text(
                    "LIVE TRACKING ACTIVE",
                    style: TextStyle(
                        color: Colors.blueAccent.withOpacity(0.3),
                        fontSize: 9,
                        letterSpacing: 2,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Info Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    color: Colors.black.withOpacity(0.5),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.location_on, color: Colors.redAccent, size: 12),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentAddress,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _currentStatus != null
                                    ? "${_currentStatus!.latitude.toStringAsFixed(5)}, ${_currentStatus!.longitude.toStringAsFixed(5)}"
                                    : "Awaiting GPS Fix...",
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    letterSpacing: 0.5
                                ),
                              ),
                            ],
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
                            minimumSize: const Size(0, 30),
                          ),
                          child: const Text("MAP", style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8,
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

  void _showLinkBandDialog() {
    final controller = TextEditingController(text: _assignedBandId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Link Hardware Band", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter Band ID (e.g. BAND-01)",
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              bool success = await _apiService.linkBandToUser(controller.text);
              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Band Linked Successfully!"), backgroundColor: Colors.green),
                  );
                  _setupBandListener(); 
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to link band. Are you logged in?"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text("LINK BAND"),
          ),
        ],
      ),
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
          _apiService.deactivateEmergency(_assignedBandId);
          setState(() => ApiService.simulateEmergency = false);
        },
        child: const Text("DEACTIVATE EMERGENCY MODE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
