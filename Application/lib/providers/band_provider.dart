import 'dart:async';
import 'package:flutter/material.dart';
import '../models/band_status.dart';
import '../services/api_service.dart';
import '../services/bluetooth_service.dart';

class BandProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  BandBluetoothService? _bluetoothService;

  BandStatus? _status;
  bool _isHardwareConnected = false;
  bool _isEmergency = false;
  String _currentAddress = "Fetching location...";
  int _batteryLevel = 100;
  String _gsmStatus = "Searching...";

  BandStatus? get status => _status;
  bool get isHardwareConnected => _isHardwareConnected;
  bool get isEmergency => _isEmergency;
  String get currentAddress => _currentAddress;
  int get batteryLevel => _batteryLevel;
  String get gsmStatus => _gsmStatus;

  void initialize(BuildContext context, {required Function(String) onEmergency}) {
    _bluetoothService = BandBluetoothService(
      onEmergencyTriggered: (msg) {
        _isEmergency = true;
        onEmergency(msg);
        notifyListeners();
      },
      onConnectionChanged: (connected) {
        _isHardwareConnected = connected;
        notifyListeners();
      },
    );
    _startPolling();
  }

  void _startPolling() {
    Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final data = await _apiService.fetchBandStatus();
        _status = data;
        
        // Simulating battery and GSM for now
        _batteryLevel = 85; 
        _gsmStatus = "Ready";

        if (data.isEmergency && !_isEmergency) {
          _isEmergency = true;
        } else if (!data.isEmergency && _isEmergency) {
          _isEmergency = false;
        }
        
        notifyListeners();
      } catch (e) {
        print("Polling error: $e");
      }
    });
  }

  void setAddress(String address) {
    _currentAddress = address;
    notifyListeners();
  }

  void stopEmergency() {
    _isEmergency = false;
    notifyListeners();
  }

  void startScan() {
    _bluetoothService?.startScan();
  }

  @override
  void dispose() {
    _bluetoothService?.dispose();
    super.dispose();
  }
}
