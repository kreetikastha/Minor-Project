import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/band_status.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class BandProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();
  StreamSubscription<BandStatus>? _statusSubscription;

  BandStatus? _status;
  Position? _currentPhonePosition;
  bool _isHardwareConnected = false; // Now means "Online in Cloud"
  bool _isEmergency = false;
  String _currentAddress = "Locating...";
  int _batteryLevel = 100;
  String _gsmStatus = "Ready";

  BandStatus? get status => _status;
  Position? get currentPhonePosition => _currentPhonePosition;
  bool get isHardwareConnected => _isHardwareConnected;
  bool get isEmergency => _isEmergency;
  String get currentAddress => _currentAddress;
  int get batteryLevel => _batteryLevel;
  String get gsmStatus => _gsmStatus;

  Future<void> initialize(BuildContext context, {required Function(String) onEmergency}) async {
    // 1. Get phone's current location immediately
    _currentPhonePosition = await _locationService.getCurrentLocation();
    notifyListeners();

    // 2. Start Listening to Cloud Firestore (Wi-Fi Bridge)
    _statusSubscription = _apiService.getStatusStream().listen((data) {
      _status = data;
      _isHardwareConnected = data.lastUpdated.isAfter(DateTime.now().subtract(const Duration(minutes: 5)));
      _isEmergency = data.isEmergency;
      
      if (_isEmergency) {
        onEmergency("CLOUD ALERT: Emergency detected via Wi-Fi!");
      }

      notifyListeners();
    }, onError: (e) {
      print("Firestore Stream Error: \$e");
    });
  }

  void setAddress(String address) {
    _currentAddress = address;
    notifyListeners();
  }

  void stopEmergency() {
    _isEmergency = false;
    // Note: We might want to send a "Reset" signal back to the hardware via Firestore
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }
}
