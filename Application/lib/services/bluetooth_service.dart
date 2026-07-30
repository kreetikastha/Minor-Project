import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'api_service.dart';

class BandBluetoothService {
  static const String SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"; 
  static const String CHARACTERISTIC_UUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; 

  BluetoothDevice? connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<List<int>>? _notificationSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  final ApiService _apiService = ApiService();
  final Function(String) onEmergencyTriggered;
  final Function(bool) onConnectionChanged;

  BandBluetoothService({
    required this.onEmergencyTriggered,
    required this.onConnectionChanged,
  });

  Future<void> startScan() async {
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      print("Bluetooth is off");
      return;
    }

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      withServices: [Guid(SERVICE_UUID)],
    );

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName.contains("Guardian") || r.device.platformName.contains("Security")) {
          FlutterBluePlus.stopScan();
          connectToDevice(r.device);
          break;
        }
      }
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    _connectionSubscription = device.connectionState.listen((state) {
      onConnectionChanged(state == BluetoothConnectionState.connected);
    });

    try {
      await device.connect();
      connectedDevice = device;

      List<BluetoothService> services = await device.discoverServices();
      for (var service in services) {
        if (service.uuid.toString().toUpperCase() == SERVICE_UUID) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase() == CHARACTERISTIC_UUID) {
              _writeCharacteristic = characteristic;
              await characteristic.setNotifyValue(true);
              
              _notificationSubscription = characteristic.onValueReceived.listen((value) {
                _handleIncomingData(value);
              });
            }
          }
        }
      }
    } catch (e) {
      print("Connection Error: $e");
      onConnectionChanged(false);
    }
  }

  void _handleIncomingData(List<int> value) {
    if (value.isEmpty) return;
    
    // Convert bytes to string (Hardware should send something like "SOS,lat,lng")
    String data = utf8.decode(value);
    print("Received from Band: $data");

    if (data.startsWith("SOS")) {
      List<String> parts = data.split(",");
      double lat = parts.length > 1 ? double.tryParse(parts[1]) ?? 0.0 : 0.0;
      double lng = parts.length > 2 ? double.tryParse(parts[2]) ?? 0.0 : 0.0;

      onEmergencyTriggered("Hardware SOS Detected at $lat, $lng");
      
      // Send this alert to our central backend
      _apiService.sendAlertToBackend(
        connectedDevice?.platformName ?? "Guardian-Band", 
        lat, 
        lng
      );
    }
  }

  Future<void> sendCommand(List<int> command) async {
    if (_writeCharacteristic != null) {
      await _writeCharacteristic!.write(command);
    }
  }

  void dispose() {
    _notificationSubscription?.cancel();
    _connectionSubscription?.cancel();
    connectedDevice?.disconnect();
  }
}
