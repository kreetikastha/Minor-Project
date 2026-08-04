import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

import '../../providers/band_provider.dart';
import '../../services/contact_service.dart';
import '../../services/sms_service.dart';
import '../../services/api_service.dart';

import '../../widgets/status_card.dart';
import '../../widgets/statistic_card.dart';
import '../../widgets/location_card.dart';
import '../../widgets/map_card.dart';
import '../../widgets/quick_action_card.dart';
import '../../widgets/contact_card.dart';
import '../../widgets/history_tile.dart';
import '../../widgets/emergency_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final ContactService _contactService = ContactService();
  final SmsService _smsService = SmsService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BandProvider>().initialize(
        context,
        onEmergency: (msg) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text(msg)),
          );
        },
      );
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _updateAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        context.read<BandProvider>().setAddress(
            "${place.locality}, ${place.administrativeArea}, ${place.country}");
      }
    } catch (e) {
      context.read<BandProvider>().setAddress("Unknown Location");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Guardian Band", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 10, color: Colors.black)])),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Cloud Status Indicator
          Consumer<BandProvider>(
            builder: (context, band, child) => Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: band.isHardwareConnected ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_sync, size: 16, color: band.isHardwareConnected ? Colors.greenAccent : Colors.redAccent),
                  const SizedBox(width: 6),
                  Text(band.isHardwareConnected ? "ONLINE" : "OFFLINE", 
                    style: TextStyle(color: band.isHardwareConnected ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          const SizedBox(width: 5),
        ],
      ),
      floatingActionButton: SOSFloatingButton(
        onPressed: () {
          // Manual SOS trigger logic
        },
      ),
      body: Consumer<BandProvider>(
        builder: (context, band, child) {
          if (band.status != null) {
            _updateAddress(band.status!.latitude, band.status!.longitude);
          } else if (band.currentPhonePosition != null && band.currentAddress == "Locating...") {
             _updateAddress(band.currentPhonePosition!.latitude, band.currentPhonePosition!.longitude);
          }

          return SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Stack(
                    children: [
                      MapCard(
                        height: MediaQuery.of(context).size.height * 0.45,
                        status: band.status,
                        phonePosition: band.currentPhonePosition,
                        markers: band.status == null ? {} : {
                          Marker(
                            markerId: const MarkerId("guardian"),
                            position: LatLng(band.status!.latitude, band.status!.longitude),
                            infoWindow: const InfoWindow(title: "Band Wearer"),
                          )
                        },
                        onMapCreated: (controller) {
                          if (band.status != null) {
                            controller.animateCamera(
                              CameraUpdate.newLatLng(LatLng(band.status!.latitude, band.status!.longitude)),
                            );
                          }
                        },
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: LocationCard(currentAddress: band.currentAddress),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        StatusCard(
                          isEmergency: band.isEmergency,
                          status: band.status,
                          pulseController: _pulseController,
                        ),
                        const SizedBox(height: 25),
                        StatisticsGrid(
                          hardwareConnected: band.isHardwareConnected,
                          isEmergency: band.isEmergency,
                          hasStatus: band.status != null,
                        ),
                        const SizedBox(height: 25),
                        QuickActionsGrid(
                          status: band.status,
                          contactService: _contactService,
                          smsService: _smsService,
                        ),
                        const SizedBox(height: 25),
                        EmergencyContactsCard(contactService: _contactService),
                        const SizedBox(height: 25),
                        const SOSHistoryCard(),
                        const SizedBox(height: 30),
                        if (band.isEmergency)
                          StopAlarmButton(
                            onPressed: () {
                              band.stopEmergency();
                              ApiService.simulateEmergency = false;
                            },
                          ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
