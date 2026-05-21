import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'widgets.dart/gradient_button.dart';
import 'utils/ui_utils.dart';
import 'forgot_password_otp_page.dart'; // Create this file next

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleSendOtp() async {
    String email = _emailController.text.trim();

    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      Messenger.show(context, "Please enter a valid email", type: MessageType.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await AuthService.forgotPasswordRequest(email: email);
      if (response['status'] == true) {
        String displayMsg = response['message'] ?? 'OTP sent successfully';
        if (response['otp'] != null) {
          displayMsg = "$displayMsg: ${response['otp']}";
        }
       // Messenger.show(context, "OTP sent to your email", type: MessageType.success);
        Messenger.show(context, displayMsg, type: MessageType.success,autoHide:false);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ForgotPasswordOtpPage(email: email)),
        );
      } else {
        Messenger.show(context, response['message'] ?? "Error sending OTP", type: MessageType.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE5F3FF), Color(0xFFE9FFE9)], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
          Positioned(top: -400, left: 0, right: -60, bottom: 490, child: Image.asset("assets/images/bot.jpeg", fit: BoxFit.cover)),
          Positioned(bottom: -60, left: -60, right: -40, top: 600, child: Image.asset("assets/images/top.jpeg", fit: BoxFit.fill)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Text('Forgot Password', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.darkGrey)),
                    const SizedBox(height: 10),
                    const Text('Enter your email to receive an OTP', textAlign: TextAlign.center),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.7),
                      ),
                      decoration: InputDecoration(hintStyle: TextStyle(
                        color: Colors.black.withOpacity(0.7),
                        fontSize: 14,
                      ), filled: true, fillColor: Colors.white, hintText: 'Email Address', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity, height: 55,
                      child: GradientButton(
                        text: _isLoading ? "Sending..." : "Send OTP",
                        gradient: const LinearGradient(colors: [Color(0xFF0A6ED1), Color(0xFF6BCF2E)]),
                        onPressed: _isLoading ? null : _handleSendOtp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}