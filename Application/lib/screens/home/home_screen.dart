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
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _setupBandListener();
  }

  Future<void> _setupBandListener() async {
    const String bandId = "guardian_device_01"; 
    _statusSubscription?.cancel();
    _statusSubscription = _apiService.getStatusStream(bandId).listen((status) {
      if (mounted) {
        // Update Marker and Camera
        final position = LatLng(status.latitude, status.longitude);
        _markers = {
          Marker(
            markerId: const MarkerId("child_band"),
            position: position,
            infoWindow: const InfoWindow(title: "Child Position"),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              status.isEmergency ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure
            ),
          )
        };
        
        // Move the map to follow the band
        _mapController?.animateCamera(CameraUpdate.newLatLng(position));

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildStatusCard(isSOS),
              const SizedBox(height: 20),
              _buildLiveMapPanel(),
              const SizedBox(height: 10),
              _buildAddressInfo(),
              const Spacer(),
              if (isSOS) _buildDeactivateButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("GUARDIAN", style: TextStyle(color: Colors.blueAccent, letterSpacing: 3, fontWeight: FontWeight.bold)),
            Text(_apiService.currentUserEmail ?? "User", style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        ScaleTransition(
          scale: Tween(begin: 1.0, end: 1.2).animate(_pulseController),
          child: const Icon(Icons.wifi_tethering, color: Colors.greenAccent, size: 20),
        ),
      ],
    );
  }

  Widget _buildStatusCard(bool isSOS) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isSOS ? Colors.redAccent.withOpacity(0.1) : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isSOS ? Colors.redAccent : Colors.white10),
      ),
      child: Column(
        children: [
          Text(isSOS ? "ALERT ACTIVE" : "SYSTEM ARMED", style: TextStyle(color: isSOS ? Colors.redAccent : Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text(_currentStatus != null ? "Last Sync: ${DateFormat('HH:mm:ss').format(_currentStatus!.lastUpdated)}" : "Connecting...", style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }

  Widget _buildLiveMapPanel() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: GoogleMap(
          initialCameraPosition: const CameraPosition(target: LatLng(27.6713, 85.3392), zoom: 15),
          markers: _markers,
          onMapCreated: (controller) => _mapController = controller,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
        ),
      ),
    );
  }

  Widget _buildAddressInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(_currentAddress, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildDeactivateButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      onPressed: () => _apiService.deactivateEmergency("guardian_device_01"),
      child: const Text("DEACTIVATE ALARM", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }
}
