import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _smsAlerts = true;
  double _pollingInterval = 5.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Alert Preferences"),
            _buildSettingTile(
              title: "Push Notifications",
              subtitle: "Receive alerts on your phone",
              trailing: Switch(
                value: _pushNotifications,
                onChanged: (val) => setState(() => _pushNotifications = val),
              ),
            ),
            _buildSettingTile(
              title: "Emergency SMS",
              subtitle: "Auto-send SMS to contacts",
              trailing: Switch(
                value: _smsAlerts,
                onChanged: (val) => setState(() => _smsAlerts = val),
              ),
            ),
            const SizedBox(height: 25),
            _buildSectionHeader("System Configuration"),
            _buildSettingTile(
              title: "Polling Interval",
              subtitle: "Sync data every ${_pollingInterval.toInt()} seconds",
              trailing: SizedBox(
                width: 120,
                child: Slider(
                  value: _pollingInterval,
                  min: 2,
                  max: 30,
                  onChanged: (val) => setState(() => _pollingInterval = val),
                ),
              ),
            ),
            const SizedBox(height: 25),
            _buildSectionHeader("Account"),
            _buildSettingTile(
              title: "Log Out",
              subtitle: "Sign out of your account",
              onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
              textColor: Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5, bottom: 15),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 13),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color textColor = Colors.white,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xff1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: trailing,
      ),
    );
  }
}
