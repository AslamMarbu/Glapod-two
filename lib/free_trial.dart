import 'package:flutter/material.dart';
import 'package:Edmaster/storage/local_storage_service.dart';

import 'student_dashboard.dart';
import 'widgets.dart/gradient_button.dart';
import 'activate_continue_page.dart';
import 'profile.dart';

class FreeTrialPage extends StatelessWidget {
  const FreeTrialPage({super.key});

  Future<Map<String, dynamic>> _getTrialInfo() async {
    final studentData = await LocalStorageService.getStudent();
    final days = await LocalStorageService.getTrialDays();

    return {'name': studentData?['name'] ?? 'Student', 'days': days};
  }

  Future<void> _continueToApp(BuildContext context) async {
    final studentData = await LocalStorageService.getStudent();
    final String? classId = studentData?['class_id']?.toString();

    if (!context.mounted) return;

    if (classId == null || classId.isEmpty || classId == '0') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const StudentDashboardPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),

      body: Stack(
        children: [
          /// SAME EDUCATIONAL BACKGROUND STYLE AS LOGIN
          Positioned.fill(
            child: Image.asset('assets/images/LBG.png', fit: BoxFit.cover),
          ),

          /// LIGHT OVERLAY
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.22)),
          ),

          SafeArea(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _getTrialInfo(),
              builder: (context, snapshot) {
                final String name =
                    snapshot.data?['name']?.toString() ?? 'Student';

                final int days = snapshot.data?['days'] is int
                    ? snapshot.data!['days']
                    : 0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
                  child: Column(
                    children: [
                      /// LOGO
                      Container(
                        width: 105,
                        height: 105,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      const Text(
                        'EdMaster',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF151515),
                          letterSpacing: .3,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        'Learn • Explore • Achieve',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 28),

                      /// MAIN TRIAL CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 25),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 25,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            /// TRIAL ICON
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFF9800),
                                    Color(0xFFFF6D00),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF9800,
                                    ).withOpacity(0.28),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.celebration_rounded,
                                color: Colors.white,
                                size: 38,
                              ),
                            ),

                            const SizedBox(height: 20),

                            Text(
                              'Welcome, $name! 🎉',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF202124),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 22),

                            /// DAYS REMAINING CARD
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 17,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFFFFF3E5),
                                    const Color(0xFFFFF8F0),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: const Color(0xFFFFB55C),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.workspace_premium_rounded,
                                    color: Color(0xFFF57C00),
                                    size: 30,
                                  ),

                                  const SizedBox(width: 12),

                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '15-Day Free Trial',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '$days days remaining',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFFF57C00),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 22),

                            Text(
                              'Your registration with EdMaster is complete, and your '
                              '15-day Free Trial is now active. Explore a world of '
                              'knowledge, fun, and learning.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14.5,
                                height: 1.55,
                              ),
                            ),

                            const SizedBox(height: 16),

                            const Text(
                              'Enjoy your Digital Knowledge Space! 🚀',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF202124),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'Step into a world where knowledge meets fun and learning '
                              'never stops. Explore, discover, play, and grow at your own pace.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14.5,
                                height: 1.55,
                              ),
                            ),

                            const SizedBox(height: 28),

                            /// CONTINUE BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: GradientButton(
                                text: 'Continue to App',
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF1688D4),
                                    Color(0xFF55D62C),
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                onPressed: () => _continueToApp(context),
                              ),
                            ),

                            const SizedBox(height: 16),

                            /// ACTIVATE BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ActivateContinuePage(),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFF7A00),
                                  side: const BorderSide(
                                    color: Color(0xFFFF8C32),
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.workspace_premium_outlined,
                                      size: 21,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Activate Premium Now',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Your trial starts from your registration date.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
