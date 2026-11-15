import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'widgets.dart/appbar_page.dart';
import 'storage/local_storage_service.dart';
import 'activate_continue_page.dart';

class SubscriptionPage extends StatelessWidget {
  const SubscriptionPage({super.key});

  static const Color navy = Color(0xFF1F2937);
  static const Color blue = Color(0xFF2F80ED);
  static const Color green = Color(0xFF27AE60);
  static const Color muted = Color(0xFF64748B);

  static const LinearGradient pageGradient = LinearGradient(
    colors: [Color(0xFFF0F7FF), Color(0xFFF7FBFA), Color(0xFFF0FAF3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient activationGradient = LinearGradient(
    colors: [blue, green],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F9F7),
      appBar: const CustomAppBar(
        height: 40,
        title: 'Subscription Info',
        isDashboard: false,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: pageGradient),
        child: FutureBuilder<Map<String, dynamic>?>(
          future: LocalStorageService.getStudent(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: blue),
              );
            }

            final student = snapshot.data;

            if (student == null) {
              return const Center(
                child: Text(
                  'User session not found.',
                  style: TextStyle(color: navy, fontSize: 14),
                ),
              );
            }

            // Existing plan detection logic
            final bool isTrial =
                student['key'] == 'trial' ||
                student['key'] == null ||
                student['key'].toString().isEmpty;

            final String planName = isTrial ? 'Trial Period' : 'Premium Plan';

            final String startLabel = isTrial
                ? 'Trial Started'
                : 'Activation Date';

            final String endLabel = isTrial ? 'Trial End Date' : 'Expiry Date';

            DateTime startDt;
            DateTime endDt;

            // Existing date calculations
            if (isTrial) {
              startDt =
                  DateTime.tryParse(
                    student['account_created_on']?.toString() ?? '',
                  ) ??
                  DateTime.now();

              final int trialDays =
                  int.tryParse(student['trail_time']?.toString() ?? '7') ?? 7;

              endDt = startDt.add(Duration(days: trialDays));
            } else {
              startDt =
                  DateTime.tryParse(
                    student['subscription_start']?.toString() ?? '',
                  ) ??
                  DateTime.tryParse(
                    student['account_created_on']?.toString() ?? '',
                  ) ??
                  DateTime.now();

              endDt =
                  DateTime.tryParse(
                    student['subscription_end']?.toString() ?? '',
                  ) ??
                  DateTime.now();
            }

            // Existing expiry and remaining days logic
            final now = DateTime.now();
            final bool isExpired = now.isAfter(endDt);
            final int daysRemaining = endDt.difference(now).inDays;

            String statusText = isTrial ? 'Free Trial' : 'Premium Member';

            if (isExpired) {
              statusText = isTrial ? 'Trial Expired' : 'Plan Expired';
            } else if (daysRemaining == 0) {
              statusText = 'Ends Today';
            }

            final String formattedStart = DateFormat(
              'MMMM dd, yyyy',
            ).format(startDt);

            final String formattedEnd = DateFormat(
              'MMMM dd, yyyy',
            ).format(endDt);

            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 28,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Current status card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                          decoration: BoxDecoration(
                            gradient: activationGradient,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: blue.withOpacity(0.16),
                                blurRadius: 30,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Current Status',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                planName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 26),

                        // Subscription details card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: const Color(0xFFE7EEF0)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF334155,
                                ).withOpacity(0.08),
                                blurRadius: 30,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildDetailRow(startLabel, formattedStart),
                              _buildDivider(),
                              _buildDetailRow(endLabel, formattedEnd),
                              _buildDivider(),
                              _buildDetailRow(
                                'Status',
                                statusText,
                                valueColor: isExpired ? Colors.red : blue,
                              ),
                              _buildDivider(),
                              _buildDetailRow(
                                'Days Remaining',
                                isExpired
                                    ? 'Expired'
                                    : '${daysRemaining < 0 ? 0 : daysRemaining + 1} Days',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Existing activation button and navigation
                        if (isTrial || isExpired)
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: activationGradient,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: blue.withOpacity(0.22),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ActivateContinuePage(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'ACTIVATE LICENSE',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 18),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFE7EEF0)),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: muted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 5,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? navy,
            ),
          ),
        ),
      ],
    );
  }
}
