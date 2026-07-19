import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BandBluetoothService {
  // Replace these with your actual Band's UUIDs if different
  static const String SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"; 
  static const String CHARACTERISTIC_UUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; 

  BluetoothDevice? connectedDevice;
  StreamSubscription<List<int>>? _notificationSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  final Function(String) onEmergencyTriggered;
  final Function(bool) onConnectionChanged;

  BandBluetoothService({
    required this.onEmergencyTriggered,
    required this.onConnectionChanged,
  });

  Future<void> startScan() async {
    // Check if bluetooth is on
    if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      print("Bluetooth is off");
      return;
    }

    // Start scanning
    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 15),
      withServices: [Guid(SERVICE_UUID)], // Scan for the specific service
    );

    // Listen to scan results
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // You can filter by name or service UUID
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
              await characteristic.setNotifyValue(true);
              _notificationSubscription = characteristic.onValueReceived.listen((value) {
                // Band sends [0x01] or similar for emergency
                if (value.isNotEmpty && value[0] == 0x01) {
                  onEmergencyTriggered("Hardware SOS Triggered!");
                }
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

  void dispose() {
    _notificationSubscription?.cancel();
    _connectionSubscription?.cancel();
    connectedDevice?.disconnect();
  }
}
