import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchProfile();
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff1E293B),
        title: const Text("Sign Out", style: TextStyle(color: Colors.white)),
        content: const Text("Are you sure you want to log out of Guardian Band?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("LOGOUT", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _apiService.logout();
      if (mounted) {
        context.read<UserProvider>().clear();
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      appBar: AppBar(
        title: const Text("User Identity", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = userProvider.profile;
          if (profile == null) {
            return const Center(child: Text("Initializing session...", style: TextStyle(color: Colors.white38)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(profile),
                const SizedBox(height: 30),
                _buildSectionLabel("Contact Information"),
                _buildInfoTile(Icons.phone_iphone_rounded, "Primary Phone", profile['phone'] ?? "Not linked"),
                _buildInfoTile(Icons.home_work_rounded, "Home Address", profile['address'] ?? "Not set"),
                const SizedBox(height: 30),
                _buildSectionLabel("Medical Vitals"),
                _buildMedicalCard(profile),
                const SizedBox(height: 40),
                _buildActionButtons(context, profile),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> profile) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blueAccent.withOpacity(0.1),
            child: const Icon(Icons.person_rounded, size: 60, color: Colors.blueAccent),
          ),
          const SizedBox(height: 15),
          Text(profile['name'] ?? "Anonymous User", 
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(profile['email'] ?? "", 
            style: const TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 12),
      child: Text(label.toUpperCase(), 
        style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5)),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white24, size: 20),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalCard(Map<String, dynamic> profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVitalItem("BLOOD", profile['blood_group'] ?? "--", Colors.redAccent),
              Container(width: 1, height: 40, color: Colors.white10),
              _buildVitalItem("ALLERGIES", profile['allergies'] ?? "None", Colors.orangeAccent),
            ],
          ),
          const Divider(height: 30, color: Colors.white10),
          Row(
            children: [
              const Icon(Icons.note_alt_outlined, color: Colors.white24, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(profile['medical_notes'] ?? "No critical notes provided.", 
                  style: const TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Map<String, dynamic> profile) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () => _showEditSheet(context, profile),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text("UPDATE IDENTITY", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          height: 55,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.redAccent),
              foregroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text("SIGN OUT", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _showEditSheet(BuildContext context, Map<String, dynamic> profile) {
    final nameCtrl = TextEditingController(text: profile['name']);
    final phoneCtrl = TextEditingController(text: profile['phone']);
    final addrCtrl = TextEditingController(text: profile['address']);
    final bloodCtrl = TextEditingController(text: profile['blood_group']);
    final allergyCtrl = TextEditingController(text: profile['allergies']);
    final notesCtrl = TextEditingController(text: profile['medical_notes']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 25, left: 25, right: 25, top: 25),
        decoration: const BoxDecoration(color: Color(0xff1E293B), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Update Identity", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 25),
              _buildEditField(nameCtrl, "Full Name"),
              _buildEditField(phoneCtrl, "Phone Number"),
              _buildEditField(addrCtrl, "Address"),
              Row(
                children: [
                  Expanded(child: _buildEditField(bloodCtrl, "Blood Group")),
                  const SizedBox(width: 15),
                  Expanded(child: _buildEditField(allergyCtrl, "Allergies")),
                ],
              ),
              _buildEditField(notesCtrl, "Critical Medical Notes", maxLines: 3),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    await context.read<UserProvider>().updateProfile(
                      name: nameCtrl.text, phone: phoneCtrl.text, address: addrCtrl.text,
                      bloodGroup: bloodCtrl.text, allergies: allergyCtrl.text, medicalNotes: notesCtrl.text,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text("SAVE CHANGES"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(TextEditingController ctrl, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          filled: true, fillColor: Colors.black26,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
