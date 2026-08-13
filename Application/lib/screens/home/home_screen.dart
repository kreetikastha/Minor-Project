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
import '../../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final NotificationService _notificationService = NotificationService();
  
  BandStatus? _currentStatus;
  StreamSubscription<BandStatus>? _statusSubscription;
  String _currentAddress = "Locating Band...";
  bool _emergencyAlreadyTriggered = false;
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
    const String bandId = "guardian_device_01"; 
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
        Placemark p = placemarks[0];
        setState(() => _currentAddress = "${p.name}, ${p.subLocality}, ${p.locality}");
      }
    } catch (_) {}
  }

  void _handleEmergency() async {
    _emergencyAlreadyTriggered = true;
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.play(UrlSource('https://www.soundjay.com/buttons/beep-01a.mp3'));
    Vibration.vibrate(duration: 2000, repeat: 1);
    _notificationService.showEmergencyNotification(address: _currentAddress);
    
    if (_currentStatus != null) {
      _apiService.logSOS(_currentStatus!, _currentAddress);
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
    final isSOS = _currentStatus?.isEmergency ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: Stack(
        children: [
          _buildBackgroundDecoration(isSOS),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildAppBar(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildMiniStatusHeader(isSOS),
                      const SizedBox(height: 45),
                      _buildSectionHeader("Real-time Vitals"),
                      const SizedBox(height: 15),
                      _buildVitalsGrid(isSOS),
                      const SizedBox(height: 45),
                      _buildSectionHeader("Quick Location"),
                      const SizedBox(height: 15),
                      _buildCompactLocationBar(),
                      const SizedBox(height: 45),
                      _buildSectionHeader("Safety Actions"),
                      const SizedBox(height: 15),
                      _buildActionGrid(),
                      if (isSOS) ...[
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
      elevation: 0, pinned: true, centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("GUARDIAN", style: TextStyle(fontSize: 10, letterSpacing: 4, fontWeight: FontWeight.w900, color: Colors.blueAccent)),
          Text(_apiService.currentUserEmail ?? "User", style: const TextStyle(fontSize: 12, color: Colors.white54)),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.add_link_rounded, color: Colors.blueAccent), onPressed: () => _showLinkBandDialog()),
        IconButton(icon: const Icon(Icons.history_rounded, color: Colors.white54), onPressed: () {}),
        const SizedBox(width: 10),
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
              Text(isEmergency ? "ALERT ACTIVE" : "SYSTEM ARMED",
                style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 34, letterSpacing: -1.0),
              ),
              const SizedBox(height: 4),
              Text(_currentStatus != null ? "Last Sync: ${DateFormat('HH:mm:ss').format(_currentStatus!.lastUpdated)}" : "Awaiting Connection...",
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
        ScaleTransition(
          scale: Tween(begin: 1.0, end: 1.2).animate(_pulseController),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: (isEmergency ? Colors.redAccent : Colors.blueAccent).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.wifi_tethering, color: isEmergency ? Colors.redAccent : Colors.blueAccent, size: 24),
          ),
        ),
      ],
    );
  }

  Widget _buildVitalsGrid(bool isEmergency) {
    return Row(
      children: [
        _buildVitalItem(Icons.favorite, "72", "BPM", Colors.pinkAccent),
        const SizedBox(width: 15),
        _buildVitalItem(Icons.battery_charging_full, "88", "%", Colors.greenAccent),
        const SizedBox(width: 15),
        _buildVitalItem(Icons.sensors, "Active", "", Colors.orangeAccent),
      ],
    );
  }

  Widget _buildVitalItem(IconData icon, String val, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              Text(unit, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactLocationBar() {
    return Container(
      height: 220, width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            CustomPaint(size: Size.infinite, painter: GridPainter()),
            Center(
              child: Icon(Icons.radar_rounded, color: Colors.blueAccent.withOpacity(0.2), size: 40),
            ),
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black.withOpacity(0.5),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_currentAddress, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                        Text("${_currentStatus?.latitude.toStringAsFixed(4) ?? '0'}, ${_currentStatus?.longitude.toStringAsFixed(4) ?? '0'}", style: const TextStyle(color: Colors.white38, fontSize: 10)),
                      ]),
                    ),
                    TextButton(
                      onPressed: () {
                        if (_currentStatus != null) {
                           launchUrl(Uri.parse(_currentStatus!.googleMapsLink), mode: LaunchMode.externalApplication);
                        }
                      },
                      style: TextButton.styleFrom(backgroundColor: Colors.blueAccent.withOpacity(0.1)),
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
      shrinkWrap: true, crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 1.4,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildActionItem(Icons.local_police_rounded, "POLICE", Colors.blue, () => launchUrl(Uri.parse("tel:100"))),
        _buildActionItem(Icons.people_alt_rounded, "CONTACTS", Colors.orange, () {}),
        _buildActionItem(Icons.sos_rounded, "SEND SOS", Colors.purpleAccent, () => _handleEmergency()),
        _buildActionItem(Icons.medical_services_rounded, "MEDICAL", Colors.redAccent, () => launchUrl(Uri.parse("tel:102"))),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.1))),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title.toUpperCase(), style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2));
  }

  Widget _buildStopAlarmButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      onPressed: () => _apiService.deactivateEmergency("guardian_device_01"),
      child: const Text("DEACTIVATE ALARM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  void _showLinkBandDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Link Hardware Band", style: TextStyle(color: Colors.white)),
        content: TextField(controller: controller, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: "Enter Band ID", hintStyle: TextStyle(color: Colors.white24))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
          ElevatedButton(onPressed: () async {
            bool success = await _apiService.linkBandToUser(controller.text);
            Navigator.pop(context);
            if (success) _setupBandListener();
          }, child: const Text("LINK")),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 1;
    for (double i = 0; i < size.width; i += 20) canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    for (double i = 0; i < size.height; i += 20) canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
