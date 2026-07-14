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
      // Clean white background
      backgroundColor: Colors.white,
      body: Center(
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
                    color: const Color.fromARGB(255, 253, 166, 104),
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
                  colors: [Color(0xfff16704), Color.fromARGB(255, 249, 116, 22)],
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
                    builder: (context) => const ActivateContinuePage(),
                  ),
                );
              },
              child: const Text(
                'Activate License Now',
                style: TextStyle(
                  color: Color.fromARGB(255, 253, 88, 5),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}