import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/band_status.dart';
import '../services/contact_service.dart';
import '../services/sms_service.dart';

class QuickActionsGrid extends StatelessWidget {
  final BandStatus? status;
  final ContactService contactService;
  final SmsService smsService;

  const QuickActionsGrid({
    Key? key,
    required this.status,
    required this.contactService,
    required this.smsService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Quick Actions",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 15),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 1.2,
          children: [
            _ActionButton(
              icon: Icons.local_police_rounded,
              title: "Police",
              color: Colors.blue,
              onTap: () => launchUrl(Uri.parse("tel:100")),
            ),
            _ActionButton(
              icon: Icons.medical_services_rounded,
              title: "Ambulance",
              color: Colors.red,
              onTap: () => launchUrl(Uri.parse("tel:102")),
            ),
            _ActionButton(
              icon: Icons.people_alt_rounded,
              title: "Contacts",
              color: Colors.orange,
              onTap: () => Navigator.pushNamed(context, '/contacts'),
            ),
            _ActionButton(
              icon: Icons.sms_rounded,
              title: "Send SOS",
              color: Colors.green,
              onTap: () async {
                if (status == null) return;
                final contacts = await contactService.getContacts();
                if (contacts.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("No Emergency Contacts Found")),
                  );
                  return;
                }
                await smsService.sendEmergencyMessages(contacts, status!);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: Colors.green,
                    content: Text("SOS Messages Sent"),
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xff1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(.15),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
