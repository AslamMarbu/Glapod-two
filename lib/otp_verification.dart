import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'services/auth_service.dart';
import 'student_dashboard.dart';
import 'utils/ui_utils.dart';
import 'free_trial.dart';
import 'widgets.dart/gradient_button.dart';
import 'storage/local_storage_service.dart';

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

  Future<void> _handleVerifyOtp() async {
    String otp = _otpController.text.trim();

    if (otp.length != 6) {
      Messenger.show(context, "Enter 6 digit OTP",type: MessageType.error);
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    final data =
        await AuthService.verifyOtp(widget.mobile, otp);

    setState(() => _isLoading = false);

    if (data['status'] == true) {
      await LocalStorageService.setToken(data["token"]);
      await LocalStorageService.setStudent(data["student"]);
      await LocalStorageService.setLoggedUser(data["student"]["id"]);
      Messenger.show(context,data['message'],type: MessageType.success);
      
       Map<String, dynamic> student = data["student"];

          String key = student["key"];
          String subscriptionEnd = student["subscription_end"];

          DateTime now = DateTime.now();

          bool isActiveSubscription = false;

          if (subscriptionEnd != "0000-00-00 00:00:00") {
            DateTime endDate = DateTime.parse(subscriptionEnd);
            isActiveSubscription = endDate.isAfter(now);
          }

          if (key == "activated" && isActiveSubscription) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => StudentDashboardPage()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => FreeTrialPage()),
            );
          }
    } else {
      
      setState(() => _hasError = true);

      _shakeController.forward(from: 0);
      _otpController.clear();

      Messenger.show(context, data['message'] ?? "Invalid OTP",type: MessageType.error);
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;

    final response =
        await AuthService.sendOtp(widget.mobile);

    if (response['status'] == true) {
      Messenger.show(context, "OTP Resent Successfully",type: MessageType.success);
      startTimer();
    } else {
      Messenger.show(context, "Failed to resend OTP",type: MessageType.error);
    }
  }

  // UI  Starts Here//
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
                        _isLoading ? null : _handleVerifyOtp,
                  ),
                ),

                const SizedBox(height: 25),

                // 🔥 RESEND SECTION
                _canResend
                    ? TextButton(
                        onPressed: _handleResendOtp,
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
