import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'login.dart';
import 'student_dashboard.dart';
import 'free_trial.dart';
import 'storage/local_storage_service.dart';
import 'services/student_service.dart';
import 'activate_continue_page.dart';
import 'profile.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;
  const SplashScreen({super.key, required this.isLoggedIn});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _startAppFlow();
  }

  Future<void> _startAppFlow() async {
    // 1. Minimum delay for branding visibility
    await Future.delayed(const Duration(seconds: 2));

    // 2. If not logged in, go straight to Login
    if (!widget.isLoggedIn) {
      _goTo(const MyHomePage());
      return;
    }

    // 3. LOGGED IN: Sync profile to check if trial/license expired overnight
    setState(() => _isSyncing = true);
    try {
      await StudentService.syncStudentProfile();
    } catch (e) {
      debugPrint("Sync failed, using last known local data: $e");
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }

    // 4. Determine Navigation based on fresh LocalStorage data
    final student = await LocalStorageService.getStudent();
    final LicenseStatus status = await LocalStorageService.getLicenseStatus();

    if (student == null) {
      _goTo(const MyHomePage());
      return;
    }

    switch (status) {
      case LicenseStatus.needProfileUpdate:
        _goTo(const ProfilePage()); // Valid license, but no class selected
        break;
      case LicenseStatus.activated:
        _goTo(const StudentDashboardPage());
        break;
      case LicenseStatus.trialing:
        _goTo(const FreeTrialPage());
        break;
      default: // expired or trialExpired
        _goTo(const ActivateContinuePage());
        break;
    }
  }

  void _goTo(Widget page) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE5F3FF), Color(0xFFE9FFE9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Wave Images
          Positioned(
            top: -400, left: 0, right: -60, bottom: 490,
            child: Image.asset("assets/images/bot.jpeg", fit: BoxFit.cover),
          ),
          Positioned(
            bottom: -60, left: -60, right: -40, top: 600,
            child: Image.asset("assets/images/top.jpeg", fit: BoxFit.fill),
          ),

          // Logo and Loading
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Displaying your updated logo.jpeg
                // Width increased to 250 to make the text in the logo readable
                Image.asset('assets/images/logo.jpeg', width: 250),

                const SizedBox(height: 30),

                // Subtle loader during API sync
                if (_isSyncing)
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1B75BB)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}