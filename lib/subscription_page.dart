import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets.dart/appbar_page.dart';
import 'storage/local_storage_service.dart';
import 'activate_continue_page.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: const CustomAppBar(
        height: 40,
        title: "Subscription Info",
        isDashboard: false,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: LocalStorageService.getStudent(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final student = snapshot.data;
          if (student == null) {
            return const Center(child: Text("User session not found."));
          }

          // --- LOGIC: PLAN DETECTION ---
          final bool isTrial = student['key'] == "trial" ||
              student['key'] == null ||
              student['key'].toString().isEmpty;

          final String planName = isTrial ? "Trial Period" : "Premium Plan";
          final String startLabel = isTrial ? "Trial Started" : "Activation Date";
          final String endLabel = isTrial ? "Trial End Date" : "Expiry Date";

          DateTime startDt;
          DateTime endDt;

          // --- LOGIC: DATE CALCULATIONS ---
          if (isTrial) {
            startDt = DateTime.tryParse(student['account_created_on'] ?? "") ?? DateTime.now();
            int trialDays = int.tryParse(student['trail_time']?.toString() ?? "7") ?? 7;
            endDt = startDt.add(Duration(days: trialDays));
          } else {
            startDt = DateTime.tryParse(student['subscription_start'] ?? "") ??
                DateTime.tryParse(student['account_created_on'] ?? "") ??
                DateTime.now();
            endDt = DateTime.tryParse(student['subscription_end'] ?? "") ?? DateTime.now();
          }

          // --- LOGIC: EXPIRY & REMAINING DAYS ---
          final now = DateTime.now();
          final bool isExpired = now.isAfter(endDt);
          final int daysRemaining = endDt.difference(now).inDays;

          String statusText = isTrial ? "Free Trial" : "Premium Member";
          if (isExpired) {
            statusText = isTrial ? "Trial Expired" : "Plan Expired";
          } else if (daysRemaining == 0 && !isExpired) {
            statusText = "Ends Today";
          }

          final String formattedStart = DateFormat('MMMM dd, yyyy').format(startDt);
          final String formattedEnd = DateFormat('MMMM dd, yyyy').format(endDt);

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
            child: Column(
              children: [
                /// TOP CARD (Restored Original Style)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xfff16704),Color.fromARGB(255, 249, 116, 22)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4)
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Current Status", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 5),
                      Text(
                          planName,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 25),

                /// DETAILS SECTION (Restored Original Style)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xfff16704).withOpacity(0.15),
                        const Color.fromARGB(255, 249, 116, 22).withOpacity(0.15),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 8)
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow(startLabel, formattedStart),
                      const Divider(height: 30, color: Colors.white, thickness: 1.2),
                      _buildDetailRow(endLabel, formattedEnd),
                      const Divider(height: 30, color: Colors.white, thickness: 1.2),
                      _buildDetailRow(
                          "Status",
                          statusText,
                          valueColor: !isExpired ? const Color(0xFF1B75BB) : Colors.red
                      ),
                      const Divider(height: 30, color: Colors.white, thickness: 1.2),
                      _buildDetailRow(
                          "Days Remaining",
                          isExpired ? "Expired" : "${daysRemaining < 0 ? 0 : daysRemaining + 1} Days"
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                /// ACTION BUTTON
                if (isTrial || isExpired)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ActivateContinuePage()),
                      );
                    },
                    child: Container(
                      width: 240,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xfff16704), Color.fromARGB(255, 249, 116, 22)]),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFF1B75BB).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5)
                          )
                        ],
                      ),
                      child: const Center(
                        child: Text(
                            "ACTIVATE LICENSE",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1
                            )
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
            label,
            style: const TextStyle(fontSize: 15, color: Color(0xFF263238), fontWeight: FontWeight.w600)
        ),
        Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor ?? Colors.black87)
        ),
      ],
    );
  }
}