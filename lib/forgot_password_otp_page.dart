import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'services/auth_service.dart';
import 'utils/ui_utils.dart';
import 'widgets.dart/gradient_button.dart';
import 'reset_password_page.dart';

class ForgotPasswordOtpPage extends StatefulWidget {
  final String email;
  const ForgotPasswordOtpPage({super.key, required this.email});

  @override
  State<ForgotPasswordOtpPage> createState() => _ForgotPasswordOtpPageState();
}

class _ForgotPasswordOtpPageState extends State<ForgotPasswordOtpPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;

  Future<void> _handleVerify() async {
    if (_otpController.text.length != 6) {
      Messenger.show(context, "Enter 6 digit OTP", type: MessageType.error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await AuthService.forgotPasswordVerifyOtp(
        email: widget.email,
        otp: _otpController.text,
      );
      if (response['status'] == true) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordPage(
                email: widget.email,
                otp: _otpController.text
            ),
          ),
        );
      } else {
        Messenger.show(context, response['message'] ?? "Invalid OTP", type: MessageType.error);
      }
    } catch (e) {
      Messenger.show(context, "Something went wrong", type: MessageType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

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
            top: -400,
            left: 0,
            right: -60,
            bottom: 490,
            child: Image.asset(
              "assets/images/bot.jpeg",
              width: MediaQuery.of(context).size.width,
              fit: BoxFit.cover,
            ),
          ),

          /// BOTTOM WAVE
          Positioned(
            bottom: -60,
            left: -60,
            right: -40,
            top: 600,
            child: Image.asset(
              "assets/images/top.jpeg",
              width: MediaQuery.of(context).size.width * 1.2,
              fit: BoxFit.fill,
            ),
          ),

          /// MAIN CONTENT
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Verify OTP",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "OTP sent to ${widget.email}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.darkGrey.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 35),

                    /// OTP INPUT
                    Pinput(
                      controller: _otpController,
                      length: 6,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: defaultPinTheme.copyWith(
                        decoration: defaultPinTheme.decoration!.copyWith(
                          border: Border.all(color: const Color(0xFF0A6ED1)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 35),

                    /// VERIFY BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: GradientButton(
                        text: _isLoading ? "Verifying..." : "Verify OTP",
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0A6ED1), Color(0xFF6BCF2E)],
                        ),
                        onPressed: _isLoading ? null : _handleVerify,
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// BACK TO LOGIN
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Back",
                        style: TextStyle(color: Colors.grey),
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