import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emergency_contact.dart';

class ContactService {
  static const String _storageKey = 'emergency_contacts';

  Future<List<EmergencyContact>> getContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? contactsJson = prefs.getString(_storageKey);
    if (contactsJson == null) return [];

    final List<dynamic> decoded = json.decode(contactsJson);
    return decoded.map((item) => EmergencyContact.fromMap(item)).toList();
  }

  Future<void> saveContact(EmergencyContact contact) async {
    final contacts = await getContacts();
    contacts.add(contact);
    await _saveAll(contacts);
  }

  Future<void> deleteContact(int index) async {
    final contacts = await getContacts();
    if (index >= 0 && index < contacts.length) {
      contacts.removeAt(index);
      await _saveAll(contacts);
    }
  }

  Future<void> _saveAll(List<EmergencyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(contacts.map((c) => c.toMap()).toList());
    await prefs.setString(_storageKey, encoded);
  }
}
