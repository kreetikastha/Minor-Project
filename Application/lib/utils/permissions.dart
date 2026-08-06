import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestAllPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.sms,
      Permission.notification,
    ].request();

    // Check if all essential permissions are granted
    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (status.isDenied || status.isPermanentlyDenied) {
        allGranted = false;
      }
    });

    return allGranted;
  }

  static Future<bool> hasLocationPermission() async {
    return await Permission.location.isGranted;
  }
}
