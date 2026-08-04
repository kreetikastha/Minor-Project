import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/emergency_contact.dart';

class ContactService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference? get _contactsRef {
    if (_uid == null) return null;
    return _db.collection('users').doc(_uid).collection('contacts');
  }

  Future<List<EmergencyContact>> getContacts() async {
    if (_contactsRef == null) return [];
    
    try {
      final snapshot = await _contactsRef!.get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return EmergencyContact.fromMap(data);
      }).toList();
    } catch (e) {
      print("Error fetching contacts: \$e");
      return [];
    }
  }

  Future<void> saveContact(EmergencyContact contact) async {
    if (_contactsRef == null) return;
    
    try {
      // Use phone number as ID to avoid duplicates
      await _contactsRef!.doc(contact.phoneNumber).set(contact.toMap());
    } catch (e) {
      print("Error saving contact: \$e");
    }
  }

  Future<void> deleteContact(int index) async {
    // Note: Since we are using Firestore, deleting by index is less efficient.
    // Better to delete by ID (phoneNumber). Let's update the UI call or fetch fresh list.
    final contacts = await getContacts();
    if (index >= 0 && index < contacts.length) {
      final contact = contacts[index];
      await _contactsRef?.doc(contact.phoneNumber).delete();
    }
  }

  // Helper for direct deletion by phone number
  Future<void> deleteContactByPhone(String phoneNumber) async {
    await _contactsRef?.doc(phoneNumber).delete();
  }
}
