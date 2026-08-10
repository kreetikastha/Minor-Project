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

  final NotificationService _notificationService = NotificationService();
  BandStatus? _currentStatus;
  StreamSubscription<BandStatus>? _statusSubscription;
  String _assignedBandId = 'guardian_device_01';
  String _currentAddress = "Locating...";
  String _triggerLocation = ""; 
  bool _emergencyAlreadyTriggered = false;
  bool _isHardwareConnected = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _setupBandListener();
  }

  Future<void> _setupBandListener() async {
    final bandId = await _apiService.getAssignedBandId();
    if (mounted) setState(() => _assignedBandId = bandId);

    // Initial load of last known data
    final lastKnown = await _apiService.fetchBandStatus();
    if (mounted && lastKnown.latitude != null) {
      setState(() => _currentStatus = lastKnown);
      _updateAddress(lastKnown.latitude!, lastKnown.longitude!);
    }

    _statusSubscription?.cancel();
    _statusSubscription = _apiService.getStatusStream(bandId).listen((status) {
      if (mounted) {
        final connected = status.lastUpdated.isAfter(DateTime.now().subtract(const Duration(minutes: 5)));
        
        if (status.isEmergency && !_emergencyAlreadyTriggered) {
          _handleEmergency(status);
        } else if (!status.isEmergency && _emergencyAlreadyTriggered) {
          _emergencyAlreadyTriggered = false;
          _stopAlarm();
        }
        setState(() {
          _currentStatus = status;
          _isHardwareConnected = connected;
        });
        if (status.latitude != null) {
           _updateAddress(status.latitude!, status.longitude!);
        }
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

  Future<void> _handleEmergency(BandStatus status) async {
    _emergencyAlreadyTriggered = true;
    _triggerLocation = _currentAddress; 
    _startAlarm();
    
    if (status.latitude != null) {
       await _apiService.sendAlertToBackend(
        _assignedBandId, status.latitude!, status.longitude!, locationName: _currentAddress
      );

      final String mapsUrl = "https://www.google.com/maps/search/?api=1&query=${status.latitude},${status.longitude}";
      if (await canLaunchUrl(Uri.parse(mapsUrl))) {
        await launchUrl(Uri.parse(mapsUrl), mode: LaunchMode.externalApplication);
      }
    }
    
    await _notificationService.showEmergencyNotification(address: _currentAddress);

    final contacts = await _contactService.getContacts();
    if (contacts.isNotEmpty) {
      await _smsService.sendEmergencyMessages(contacts, status);
    }
  }

  void _startAlarm() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(UrlSource('https://www.soundjay.com/buttons/beep-01a.mp3'));
    if (await Vibration.hasVibrator() == true) {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEmergency = _currentStatus?.isEmergency ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Stack(
        children: [
          _buildBackgroundDecoration(isEmergency),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildMiniStatusHeader(isEmergency),
                      const SizedBox(height: 45),
                      _buildSectionHeader("Quick Location"),
                      const SizedBox(height: 15),
                      _buildCompactLocationBar(),
                      const SizedBox(height: 45),
                      _buildSectionHeader("Safety Actions"),
                      const SizedBox(height: 15),
                      _buildActionGrid(),
                      if (isEmergency) ...[
                        const SizedBox(height: 40),
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
      top: -150, right: -100,
      child: Container(
        width: 400, height: 400,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: isEmergency
                ? [Colors.redAccent.withValues(alpha: 0.2), Colors.transparent]
                : [Colors.blueAccent.withValues(alpha: 0.15), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0, pinned: true, centerTitle: false, toolbarHeight: 70,
      title: const Text("GUARDIAN", style: TextStyle(fontSize: 16, letterSpacing: 6, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
      actions: [
        IconButton(icon: const Icon(Icons.add_link_rounded, color: Colors.blueAccent), onPressed: () => _showLinkBandDialog()),
        IconButton(icon: const Icon(Icons.history_rounded, color: Colors.white54), onPressed: () => Navigator.pushNamed(context, '/history')),
        const SizedBox(width: 10),
      ],
    );
  }

  Widget _buildMiniStatusHeader(bool isEmergency) {
    final statusColor = isEmergency ? Colors.redAccent : const Color(0xFF10B981);
    
    String statusSubtitle = "Checking connection...";
    if (_currentStatus != null) {
      final time = DateFormat('HH:mm:ss').format(_currentStatus!.lastUpdated);
      if (isEmergency) {
        statusSubtitle = "SOS Triggered at $time\n📍 $_triggerLocation";
      } else if (_isHardwareConnected) {
        statusSubtitle = "Live at $time\n📍 $_currentAddress";
      } else {
        statusSubtitle = "Offline. Last known at $time\n📍 $_currentAddress";
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEmergency ? "ALERT ACTIVE" : (_isHardwareConnected ? "SYSTEM ARMED" : "BAND OFFLINE"),
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 34, letterSpacing: -1.0),
              ),
              const SizedBox(height: 4),
              Text(
                statusSubtitle,
                style: const TextStyle(color: Colors.white38, fontSize: 13, height: 1.4),
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
          color: (isEmergency ? Colors.redAccent : Colors.blueAccent).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isHardwareConnected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
          color: _isHardwareConnected ? Colors.blueAccent : Colors.white24,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildCompactLocationBar() {
    return Container(
      height: 220, width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            CustomPaint(size: Size.infinite, painter: GridPainter()),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radar_rounded, color: Colors.blueAccent.withValues(alpha: 0.2), size: 40),
                  const SizedBox(height: 8),
                  Text(_isHardwareConnected ? "LIVE TRACKING ACTIVE" : "LAST KNOWN POSITION",
                    style: TextStyle(color: Colors.blueAccent.withValues(alpha: 0.3), fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.black.withValues(alpha: 0.5),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_currentAddress, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _currentStatus != null && _currentStatus!.latitude != null
                                ? "${_currentStatus!.latitude!.toStringAsFixed(5)}, ${_currentStatus!.longitude!.toStringAsFixed(5)}"
                                : "Awaiting GPS Fix...",
                            style: const TextStyle(color: Colors.white54, fontFamily: 'monospace', fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        if (_currentStatus != null && _currentStatus!.latitude != null) {
                          launchUrl(Uri.parse("https://www.google.com/maps/search/?api=1&query=${_currentStatus!.latitude},${_currentStatus!.longitude}"));
                        }
                      },
                      style: TextButton.styleFrom(backgroundColor: Colors.blueAccent.withValues(alpha: 0.1)),
                      child: const Text("MAP", style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
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
      shrinkWrap: true, crossAxisCount: 2, crossAxisSpacing: 18, mainAxisSpacing: 18, childAspectRatio: 1.3,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildCompactAction(Icons.local_police_rounded, "POLICE", Colors.blue, () => launchUrl(Uri.parse("tel:100"))),
        _buildCompactAction(Icons.people_alt_rounded, "CONTACTS", Colors.orange, () => Navigator.pushNamed(context, '/contacts')),
        _buildCompactAction(Icons.sos_rounded, "SEND SOS", Colors.purpleAccent, () async {
          final contacts = await _contactService.getContacts();
          if (_currentStatus != null && contacts.isNotEmpty) {
            _handleEmergency(_currentStatus!);
          }
        }),
        _buildCompactAction(Icons.medical_services_rounded, "MEDICAL", Colors.redAccent, () => launchUrl(Uri.parse("tel:102"))),
      ],
    );
  }

  Widget _buildCompactAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)]),
          borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2));
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
          decoration: const InputDecoration(hintText: "Enter Band ID", hintStyle: TextStyle(color: Colors.white24)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(
            onPressed: () async {
              bool success = await _apiService.linkBandToUser(controller.text);
              if (mounted) {
                Navigator.pop(context);
                if (success) _setupBandListener(); 
              }
            },
            child: const Text("LINK BAND"),
          ),
        ],
      ),
    );
  }

  Widget _buildStopAlarmButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 65), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
      onPressed: () { _stopAlarm(); _apiService.deactivateEmergency(_assignedBandId); setState(() => ApiService.simulateEmergency = false); },
      child: const Text("DEACTIVATE EMERGENCY MODE", style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.02)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 20) canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += 20) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
