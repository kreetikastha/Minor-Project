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
              status.isEmergency ? BitmapDescriptor.hueRed : BitmapDescriptor.defaultMarkerWithHue(210)
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

  // ... (keeping _updateAddress, _handleEmergency, _stopAlarm as they are)

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
              _buildLiveMapPanel(), // NEW: Embedded Google Map
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

  Widget _buildLiveMapPanel() {
    return Container(
      height: 250,
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
  
  // ... (Rest of the helper widgets)
}
}
