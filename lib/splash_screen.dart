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
import 'package:lottie/lottie.dart';

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
      backgroundColor: const Color(0xFFF5F7FB),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6), Color(0xFF60A5FA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),

              Container(
  width: 120,
  height: 120,
  decoration: BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    boxShadow: const [
      BoxShadow(
        color: Colors.black26,
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
    ],
  ),
  child: ClipOval(
    child: OverflowBox(
      maxWidth: 150,
      maxHeight: 150,
      child: Image.asset(
        "assets/images/logo.png",
        width: 135,
        height: 135,
        fit: BoxFit.contain,
      ),
    ),
  ),
),

              const SizedBox(height: 24),

              const Text(
                "EdMaster",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Learn • Practice • Achieve",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),

              const SizedBox(height: 40),

              Lottie.asset("assets/animations/loading.json", height: 180),

              const SizedBox(height: 15),

              AnimatedOpacity(
                opacity: _isSyncing ? 1 : 0.8,
                duration: const Duration(milliseconds: 500),
                child: Text(
                  _isSyncing ? "Preparing your lessons..." : "Welcome Back",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const Spacer(),

              const Padding(
                padding: EdgeInsets.only(bottom: 25),
                child: Text(
                  "Powered by Glapod Tech",
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
