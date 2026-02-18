import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'services/auth_service.dart';
import 'free_trial_page.dart';
import 'widgets.dart/gradient_button.dart';
import 'package:shared_preferences/shared_preferences.dart';


class OtpVerificationPage extends StatefulWidget {
  final String mobile;

  const OtpVerificationPage({super.key, required this.mobile});

  @override
  State<OtpVerificationPage> createState() =>
      _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _otpController =
      TextEditingController();

  bool _isLoading = false;
  bool _hasError = false;

  // 🔥 Shake Animation
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // 🔥 Timer
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

    _shakeAnimation =
        Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _shakeController,
        curve: Curves.elasticIn,
      ),
    );
  }

  void startTimer() {
    _secondsRemaining = 60;
    _canResend = false;

    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          setState(() => _canResend = true);
          timer.cancel();
        }
      },
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    _shakeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> verifyOtp() async {
    String otp = _otpController.text.trim();

    if (otp.length != 6) {
      showMessage("Enter 6 digit OTP");
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final response =
        await AuthService.verifyOtp(widget.mobile, otp);

    setState(() => _isLoading = false);

    if (response['status'] == true) {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString("token", response['token']);

      showMessage(response['message']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const FreeTrialPage(),
        ),
      );
    } else {
      // ❌ WRONG OTP
      setState(() => _hasError = true);

      _shakeController.forward(from: 0);
      _otpController.clear();

      showMessage(response['message'] ?? "Invalid OTP");
    }
  }

  Future<void> resendOtp() async {
    if (!_canResend) return;

    final response =
        await AuthService.sendOtp(widget.mobile);

    if (response['status'] == true) {
      showMessage("OTP Resent Successfully");
      startTimer();
    } else {
      showMessage("Failed to resend OTP");
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
        border: Border.all(
          color: _hasError ? Colors.red : Colors.grey,
        ),
      ),
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/image.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Verify OTP',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 25),

                // 🔥 SHAKE WRAPPER
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                          _shakeAnimation.value *
                              (1 -
                                  (_shakeController.value *
                                      2).abs()),
                          0),
                      child: child,
                    );
                  },
                  child: Pinput(
                    controller: _otpController,
                    length: 6,
                    enabled: !_isLoading,
                    defaultPinTheme: defaultPinTheme,
                    //onCompleted: (value) {
                     // verifyOtp();
                   // },
                   onTap: () {
                      if (_hasError) {
                        setState(() => _hasError = false);
                      }
                    },
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: GradientButton(
                    text:
                        _isLoading ? "Verifying..." : "Verify OTP",
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A6ED1), Color(0xFF6BCF2E)],
                    ),
                    onPressed:
                        _isLoading ? null : verifyOtp,
                  ),
                ),

                const SizedBox(height: 25),

                // 🔥 RESEND SECTION
                _canResend
                    ? TextButton(
                        onPressed: resendOtp,
                        child: const Text(
                          "Resend OTP",
                          style: TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    : Text(
                        "Resend OTP in $_secondsRemaining seconds",
                        style: const TextStyle(
                            color: Colors.grey),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
