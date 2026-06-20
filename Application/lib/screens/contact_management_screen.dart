import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';
import '../services/contact_service.dart';

class ContactManagementScreen extends StatefulWidget {
  const ContactManagementScreen({super.key});

  @override
  State<ContactManagementScreen> createState() => _ContactManagementScreenState();
}

class _ContactManagementScreenState extends State<ContactManagementScreen> {
  final ContactService _contactService = ContactService();
  List<EmergencyContact> _contacts = [];
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await _contactService.getContacts();
    setState(() {
      _contacts = contacts;
    });
  }

  void _addContact() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Add Emergency Contact", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Name",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            TextField(
              controller: _phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "Phone Number",
                labelStyle: TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty) {
                await _contactService.saveContact(
                  EmergencyContact(name: _nameController.text, phoneNumber: _phoneController.text),
                );
                _nameController.clear();
                _phoneController.clear();
                if (mounted) Navigator.pop(context);
                _loadContacts();
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Contacts"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _contacts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  const Text("No emergency contacts added yet.", style: TextStyle(color: Colors.white54)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.redAccent.withOpacity(0.2),
                      child: const Icon(Icons.person, color: Colors.redAccent),
                    ),
                    title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(contact.phoneNumber, style: const TextStyle(color: Colors.white70)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () async {
                        await _contactService.deleteContact(index);
                        _loadContacts();
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addContact,
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add Contact", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
