import 'package:flutter/material.dart';
import 'package:glapod/storage/local_storage_service.dart';
import 'student_dashboard.dart';
import 'widgets.dart/gradient_button.dart';
import 'activate_continue_page.dart';
import 'profile.dart';
class FreeTrialPage extends StatelessWidget {
  const FreeTrialPage({super.key});

  // Helper to fetch both name and days at once
  Future<Map<String, dynamic>> _getTrialInfo() async {
    final studentData = await LocalStorageService.getStudent();
    final days = await LocalStorageService.getTrialDays();
    return {
      'name': studentData?['name'] ?? 'User',
      'days': days,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// BACKGROUND GRADIENT
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE5F3FF), Color(0xFFE9FFE9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          /// TOP WAVE
          Positioned(
            top: -400, left: 0, right: -60, bottom: 490,
            child: Image.asset("assets/images/bot.jpeg", fit: BoxFit.cover),
          ),

          /// BOTTOM WAVE
          Positioned(
            bottom: -60, left: -60, right: -40, top: 600,
            child: Image.asset("assets/images/top.jpeg", fit: BoxFit.fill),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Combined FutureBuilder for Name and Days
                FutureBuilder<Map<String, dynamic>>(
                  future: _getTrialInfo(),
                  builder: (context, snapshot) {
                    final String name = snapshot.data?['name'] ?? 'User';
                    final int days = snapshot.data?['days'] ?? 0;

                    return Container(
                      width: 250,
                      height: 100,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 94, 157, 209),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Hi $name,', // Dynamically showing name
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Free trial $days days remaining',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: 300,
                  height: 55,
                  child: GradientButton(
                    text: 'Continue to App',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A6ED1), Color(0xFF6BCF2E)],
                    ),
                    onPressed: () async {
                      // 1. Fetch student data
                      final studentData = await LocalStorageService.getStudent();

                      // 2. Extract class_id and check if it's null or empty
                      final String? classId = studentData?['class_id']?.toString();

                      if (context.mounted) {
                        if (classId == null || classId.isEmpty) {
                          // REDIRECT TO PROFILE: If class is not updated
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfilePage()),
                          );
                        } else {
                          // REDIRECT TO DASHBOARD: If class is already there
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const StudentDashboardPage()),
                                (route) => false,
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ActivateContinuePage()),
                    );
                  },
                  child: const Text(
                    'Activate License Now',
                    style: TextStyle(
                      color: Color.fromARGB(255, 66, 180, 70),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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