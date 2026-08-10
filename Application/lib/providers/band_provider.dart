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
  bool _isHardwareConnected = false;
  bool _isEmergency = false;
  String _currentAddress = "Locating...";
  
  BandStatus? get status => _status;
  Position? get currentPhonePosition => _currentPhonePosition;
  bool get isHardwareConnected => _isHardwareConnected;
  bool get isEmergency => _isEmergency;
  String get currentAddress => _currentAddress;

  Future<void> initialize(BuildContext context, {required Function(String) onEmergency}) async {
    // 1. Get phone's location for initial map focus
    _currentPhonePosition = await _locationService.getCurrentLocation();
    notifyListeners();

    // 2. Fetch "Last Known" status from Firestore immediately
    final bandId = await _apiService.getAssignedBandId();
    final lastStatus = await _apiService.fetchBandStatus(); 
    _status = lastStatus;
    notifyListeners();

    // 3. Start Live Real-time Listener
    _statusSubscription?.cancel();
    _statusSubscription = _apiService.getStatusStream(bandId).listen((data) {
      _status = data;
      _isEmergency = data.isEmergency;
      
      // Hardware is connected if updated in last 5 minutes
      _isHardwareConnected = data.lastUpdated.isAfter(DateTime.now().subtract(const Duration(minutes: 5)));

      if (_isEmergency) {
        onEmergency("LIVE ALERT: SOS Triggered!");
      }

      notifyListeners();
    });
  }

  void setAddress(String address) {
    _currentAddress = address;
    notifyListeners();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    super.dispose();
  }
}
