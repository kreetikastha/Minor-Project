import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/contact_service.dart';

class EmergencyContactsCard extends StatelessWidget {
  final ContactService contactService;

  const EmergencyContactsCard({
    Key? key,
    required this.contactService,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: contactService.getContacts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final contacts = snapshot.data!;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xff1E293B),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Emergency Contacts",
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                if (contacts.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        "No contacts available",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                  )
                else
                  ...contacts.map((contact) => Card(
                        color: Colors.black26,
                        elevation: 0,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              contact.name.isNotEmpty ? contact.name[0] : "?",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            contact.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            contact.phoneNumber,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.call, color: Colors.green),
                            onPressed: () => launchUrl(Uri.parse("tel:${contact.phoneNumber}")),
                          ),
                        ),
                      )).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
