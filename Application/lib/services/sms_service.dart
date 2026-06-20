import 'package:url_launcher/url_launcher.dart';
import '../models/emergency_contact.dart';
import '../models/band_status.dart';

class SmsService {
  Future<void> sendEmergencyMessages(List<EmergencyContact> contacts, BandStatus status) async {
    final String googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=${status.latitude},${status.longitude}';
    final String message = "EMERGENCY ALERT: Triple Tap detected on my Security Band. My location: $googleMapsUrl";

    if (contacts.isEmpty) return;

    // For simplicity and compatibility, we open the default SMS app with the first contact
    // You can manually send to others or I can show you how to loop them if needed.
    final String phoneNumber = contacts[0].phoneNumber;
    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    if (await canLaunchUrl(smsLaunchUri)) {
      await launchUrl(smsLaunchUri);
    } else {
      print("Could not launch SMS app");
    }
  }
}
