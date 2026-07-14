import 'package:flutter/material.dart';
import 'widgets.dart/appbar_page.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: const CustomAppBar(
        height: 40,
        title: "Terms & Conditions",
        isDashboard: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            // UPDATED: Darker gradient to match AppBar (Opacity increased to 0.22)
            gradient: LinearGradient(
              colors: [
                const Color(0xfff16704).withOpacity(0.22),
                const Color.fromARGB(255, 249, 116, 22).withOpacity(0.22),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
            // White border helps the darker gradient stand out from the light background
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.gavel_rounded, color: Color(0xFF1B75BB), size: 28),
                  SizedBox(width: 12),
                  Text(
                    "Terms of Service",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1B75BB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Last Updated: March 2026",
                style: TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    fontWeight: FontWeight.w600
                ),
              ),
              const Divider(height: 40, thickness: 1.2, color: Colors.white),

              _buildSectionTitle("1. Acceptance of Terms"),
              _buildBodyText("By accessing Edu-Picks, you agree to be bound by these Terms and Conditions and all applicable laws and regulations."),

              _buildSectionTitle("2. Educational Use"),
              _buildBodyText("This app is designed for educational purposes. Users are expected to engage with the 'Prediction' and 'Guess Name' activities fairly."),

              _buildSectionTitle("3. Subscription & Licensing"),
              _buildBodyText("Licenses activated via activation keys are valid for the duration specified at the time of purchase. Subscriptions are non-transferable."),

              _buildSectionTitle("4. User Privacy"),
              _buildBodyText("We value your privacy. Your profile data (Name, Email, Class) is used solely to enhance your learning experience and track progress."),

              _buildSectionTitle("5. Intellectual Property"),
              _buildBodyText("All content, including images used in Guessing games and educational text, is the property of Edu-Picks and may not be copied without permission."),

              const SizedBox(height: 40),

              // Bottom "Badge" style footer
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFF1B75BB).withOpacity(0.3)),
                  ),
                  child: const Text(
                    "Thank you for learning with us!",
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Color(0xFF263238), // Slightly darker for better contrast on gradient
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildBodyText(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        color: Colors.black87,
        height: 1.6,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}