import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'storage/local_storage_service.dart';
import 'services/auth_service.dart';
import 'utils/ui_utils.dart';
import 'free_trial.dart';
import 'widgets.dart/gradient_button.dart';
import 'profile.dart';

class OtpVerificationPage extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String device;
  final String country; // Added
  final String state;

  const OtpVerificationPage({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.device,
    required this.country, // Added
    required this.state,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  bool _hasError = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();

    startTimer();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void startTimer() {
    _secondsRemaining = 60;
    _canResend = false;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _shakeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleVerifyOtp() async {
    String otp = _otpController.text.trim();

    if (otp.length != 6) {
      Messenger.show(context, "Enter 6 digit OTP", type: MessageType.error);
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await AuthService.otpVerification(
        name: widget.name,
        email: widget.email,
        phone: widget.phone,
        password: widget.password,
        otp: otp,
        device: widget.device,
        country: widget.country, // Add this!
        state: widget.state,
      );

      if (response['status'] == true || response['status'] == "true") {

        // 1. Success Message

        Messenger.hide(context);
        Messenger.show(
          context,
          response['message'] ?? "Verification successful",
          type: MessageType.success,
        );

        // 2. Data Persistence
        if (response['token'] != null) {
          final student = response['student'];

          // Save the main session
          await LocalStorageService.saveUserSession(
            token: response['token'],
            studentData: student,
          );

          // Calculate and Save Trial Days (Same logic as login)
          DateTime createdAt = student['account_created_on'] != null
              ? DateTime.parse(student['account_created_on'])
              : DateTime.now();
          int trialAllowed = student['trail_time'] ?? 7;
          int daysUsed = DateTime.now().difference(createdAt).inDays;
          int remaining = trialAllowed - daysUsed;

          await LocalStorageService.saveTrialDays(remaining);
        }

        if (mounted) {
          // 3. Mandatory Redirection
          // Since this is a new registration, class_id is null,
          // so ProfilePage is the correct destination.
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const FreeTrialPage()),
                (route) => false,
          );
        }
      } else {
        // 3. Handle Failure (e.g., "Invalid or expired OTP")
        setState(() => _hasError = true);
        _shakeController.forward(from: 0);


        Messenger.show(
          context,
          response['message'] ?? "Verification failed",
          type: MessageType.error,
        );
      }
    } catch (e) {
      Messenger.show(
        context,
        "Something went wrong. Please try again.",
        type: MessageType.error,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;

    final response = await AuthService.registerAndSendOtp(
      name: widget.name,
      email: widget.email,
      phone: widget.phone,
      password: widget.password,
      device: widget.device,
      country: widget.country, // Add this!
      state: widget.state,
    );

    if (response['status'] == true) {
      // Dynamically use the message from API ("OTP sent successfully")
      String msg = response['message'] ?? "OTP Resent Successfully";

      // Optional: Append OTP for testing
      if (response['otp'] != null) {
        msg = "$msg: ${response['otp']}";
      }

      Messenger.show(context, msg, type: MessageType.success);
      startTimer();
    } else {
      // Dynamically use the error message from API
      String errorMsg = response['message'] ?? "Failed to resend OTP";
      Messenger.show(context, errorMsg, type: MessageType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _hasError ? Colors.red : Colors.grey),
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
                      ),
                    ),

                    const SizedBox(height: 25),

                    AnimatedBuilder(
                      animation: _shakeAnimation,
                      builder: (context, child) {
                        // Simple sine wave shake
                        final double offset =
                            (0.5 - (0.5 - _shakeController.value).abs()) * 20;
                        return Transform.translate(
                          offset: Offset(_hasError ? offset : 0, 0),
                          child: child,
                        );
                      },

                      child: Pinput(
                        controller: _otpController,
                        length: 6,
                        // Keep it enabled unless actually loading to allow corrections
                        enabled: !_isLoading,
                        defaultPinTheme: defaultPinTheme,

                        // FIX: Allow rewriting by clearing error state when value changes
                        onChanged: (value) {
                          if (_hasError) {
                            setState(() => _hasError = false);
                          }
                        },

                        // OPTIONAL: Auto-submit when the 6th digit is entered
                        // onCompleted: (pin) => _handleVerifyOtp(),

                        // TEXT CONFIGURATION
                        showCursor: true,
                        autofocus: true,
                      ),
                    ),

                    const SizedBox(height: 25),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: GradientButton(
                        text: _isLoading ? "Verifying..." : "Verify OTP",
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0A6ED1), Color(0xFF6BCF2E)],
                        ),
                        onPressed: _isLoading ? null : _handleVerifyOtp,
                      ),
                    ),

                    const SizedBox(height: 25),

                    _canResend
                        ? TextButton(
                            onPressed: _handleResendOtp,
                            child: const Text(
                              "Resend OTP",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          )
                        : Text(
                            "Resend OTP in $_secondsRemaining seconds",
                            style: const TextStyle(color: Colors.grey),
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
