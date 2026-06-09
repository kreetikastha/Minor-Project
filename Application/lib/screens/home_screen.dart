import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/band_status.dart';
import '../models/emergency_contact.dart';
import '../services/api_service.dart';
import '../services/contact_service.dart';
import 'contact_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  BandStatus? _currentStatus;
  Timer? _timer;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    // Poll the backend every 5 seconds for updates from the SIM band
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final status = await _apiService.fetchBandStatus();
      if (mounted) {
        setState(() {
          _currentStatus = status;
        });
        _updateMap();

        if (status.isEmergency) {
          _showEmergencyAlert();
        }
      }
    });
  }

  void _updateMap() {
    if (_mapController != null && _currentStatus != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentStatus!.latitude, _currentStatus!.longitude),
        ),
      );
    }
  }

  void _showEmergencyAlert() {
    // Basic local notification or dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        title: const Text("EMERGENCY ALERT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          "A Triple Tap has been detected from the Security Band!",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("DISMISS", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () => launchUrl(Uri.parse("tel:100")), // Default emergency number
            child: const Text("CALL EMERGENCY", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Security Band Monitor"),
        backgroundColor: _currentStatus?.isEmergency == true ? Colors.red : Colors.indigo,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text("Simulation Settings", style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            SwitchListTile(
              title: const Text("Simulate Emergency"),
              subtitle: const Text("Toggles Triple Tap Alert"),
              value: ApiService.simulateEmergency,
              onChanged: (bool value) {
                setState(() {
                  ApiService.simulateEmergency = value;
                });
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStatusHeader(),
          Expanded(
            child: _currentStatus == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(_currentStatus!.latitude, _currentStatus!.longitude),
                      zoom: 15,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    markers: {
                      Marker(
                        markerId: const MarkerId("band_location"),
                        position: LatLng(_currentStatus!.latitude, _currentStatus!.longitude),
                        infoWindow: const InfoWindow(title: "Band Position"),
                        icon: BitmapDescriptor.defaultMarkerWithHue(
                          _currentStatus!.isEmergency ? BitmapDescriptor.hueRed : BitmapDescriptor.hueAzure,
                        ),
                      ),
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _apiService.fetchBandStatus(), // Manual refresh
        label: const Text("Refresh Status"),
        icon: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildStatusHeader() {
    if (_currentStatus == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      color: _currentStatus!.isEmergency ? Colors.red[100] : Colors.green[100],
      child: Row(
        children: [
          Icon(
            _currentStatus!.isEmergency ? Icons.warning_amber_rounded : Icons.check_circle_outline,
            color: _currentStatus!.isEmergency ? Colors.red : Colors.green,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentStatus!.isEmergency ? "STATUS: EMERGENCY TRIGGERED" : "STATUS: NORMAL",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _currentStatus!.isEmergency ? Colors.red[900] : Colors.green[900],
                  ),
                ),
                Text(
                  "Last Updated: ${DateFormat('HH:mm:ss').format(_currentStatus!.lastUpdated)}",
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
