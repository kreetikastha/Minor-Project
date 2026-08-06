import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app/routes.dart';
import '../../utils/permissions.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() {
    Future.delayed(const Duration(seconds: 4), () async {
      if (!mounted) return;
      
      // Request essential permissions before proceeding
      await PermissionHelper.requestAllPermissions();

      if (!mounted) return;

      // Check if user is already logged in
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // User is logged in, go to Home
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        // No user, go to Login
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Container
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.security_rounded,
                size: 100,
                color: Colors.blue,
              ),
            )
            .animate()
            .scale(duration: 1000.ms, curve: Curves.elasticOut)
            .shimmer(delay: 1500.ms, duration: 1800.ms),
            
            const SizedBox(height: 30),
            
            const Text(
              "GUARDIAN",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                letterSpacing: 10,
                color: Colors.white,
              ),
            )
            .animate()
            .fadeIn(delay: 500.ms, duration: 800.ms)
            .slideY(begin: 0.5, end: 0),

            const Text(
              "YOUR SAFETY, OUR PRIORITY",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                letterSpacing: 3,
                color: Colors.white54,
              ),
            )
            .animate()
            .fadeIn(delay: 1200.ms, duration: 800.ms),
            
            const SizedBox(height: 50),
            
            const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            )
            .animate()
            .fadeIn(delay: 2000.ms),
          ],
        ),
      ),
    );
  }
}
