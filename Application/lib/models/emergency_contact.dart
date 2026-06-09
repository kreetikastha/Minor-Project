import 'dart:convert';

class EmergencyContact {
  final String name;
  final String phoneNumber;

  EmergencyContact({required this.name, required this.phoneNumber});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory EmergencyContact.fromJson(String source) => EmergencyContact.fromMap(json.decode(source));
}
