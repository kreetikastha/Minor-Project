import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleBiometric() async {
    try {
      bool canCheck = await _localAuth.canCheckBiometrics;
      if (canCheck) {
        bool authenticated = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to access Guardian Band',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (authenticated) {
          if (mounted) Navigator.pushReplacementNamed(context, '/home');
        }
      }
    } catch (e) {
      print("Biometric Error: $e");
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await _apiService.login(email, password);
    setState(() => _isLoading = false);

    if (success) {
      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid credentials"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff1E3A8A), Color(0xff0F172A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.security_rounded, size: 80, color: Colors.white),
                ),
                const SizedBox(height: 30),
                const Text("GUARDIAN", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 6, color: Colors.white)),
                const Text("SMART SECURITY BAND", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, letterSpacing: 2, color: Colors.white70)),
                const SizedBox(height: 60),
                TextField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    labelStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.email_rounded, color: Colors.blueAccent),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.lock_rounded, color: Colors.blueAccent),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SIGN IN", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                      child: IconButton(
                        icon: const Icon(Icons.fingerprint_rounded, color: Colors.blueAccent, size: 30),
                        onPressed: _handleBiometric,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Secure Connection", style: TextStyle(color: Colors.white24, fontSize: 12)),
                    SizedBox(width: 8),
                    Icon(Icons.lock_outline, size: 14, color: Colors.white24),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
