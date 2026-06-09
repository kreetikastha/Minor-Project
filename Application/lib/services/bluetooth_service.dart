import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  // Replace these with your actual Band's UUIDs
  static const String SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"; // Example UART Service
  static const String CHARACTERISTIC_UUID = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // Example RX Characteristic

  BluetoothDevice? connectedDevice;
  StreamSubscription<List<int>>? notificationSubscription;

  final Function(String) onEmergencyTriggered;

  BluetoothService({required this.onEmergencyTriggered});

  Future<void> startScan() async {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.platformName.contains("SecurityBand")) { // Change to your band's name
          FlutterBluePlus.stopScan();
          connectToDevice(r.device);
          break;
        }
      }
    });
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await device.connect();
    connectedDevice = device;

    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.uuid.toString().toUpperCase() == CHARACTERISTIC_UUID) {
          await characteristic.setNotifyValue(true);
          notificationSubscription = characteristic.lastValueStream.listen((value) {
            // Assume the band sends a specific code for triple tap, e.g., [0x03]
            if (value.isNotEmpty && value[0] == 0x03) {
              onEmergencyTriggered("Triple Tap Detected!");
            }
          });
        }
      }
    }
  }

  void dispose() {
    notificationSubscription?.cancel();
    connectedDevice?.disconnect();
  }
}
