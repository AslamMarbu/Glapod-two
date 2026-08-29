import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';

import 'storage/local_storage_service.dart';
import 'services/auth_service.dart';
import 'utils/ui_utils.dart';
import 'free_trial.dart';
import 'widgets.dart/gradient_button.dart';

class OtpVerificationPage extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String password;
  final String device;
  final String country;
  final String state;

  const OtpVerificationPage({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.device,
    required this.country,
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

    _startTimer();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _shakeAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    _shakeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();

    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        timer.cancel();

        setState(() {
          _canResend = true;
        });
      }
    });
  }

  String _maskEmail(String email) {
    if (!email.contains('@')) return email;

    final parts = email.split('@');
    final name = parts[0];
    final domain = parts[1];

    if (name.length <= 2) {
      return '${name[0]}***@$domain';
    }

    return '${name.substring(0, 2)}***@$domain';
  }

  Future<void> _handleVerifyOtp() async {
    final String otp = _otpController.text.trim();

    if (otp.length != 6) {
      Messenger.show(
        context,
        'Please enter the 6-digit OTP',
        type: MessageType.error,
      );
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
        country: widget.country,
        state: widget.state,
      );

      if (response['status'] == true || response['status'] == 'true') {
        Messenger.hide(context);

        Messenger.show(
          context,
          response['message'] ?? 'Verification successful',
          type: MessageType.success,
        );

        if (response['token'] != null && response['student'] != null) {
          final student = response['student'];

          await LocalStorageService.saveUserSession(
            token: response['token'],
            studentData: student,
          );

          final DateTime createdAt = student['account_created_on'] != null
              ? DateTime.parse(student['account_created_on'])
              : DateTime.now();

          final int trialAllowed =
              int.tryParse(student['trail_time']?.toString() ?? '15') ?? 15;

          final int daysUsed = DateTime.now().difference(createdAt).inDays;

          final int remaining = (trialAllowed - daysUsed).clamp(
            0,
            trialAllowed,
          );

          await LocalStorageService.saveTrialDays(remaining);
        }

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const FreeTrialPage()),
          (route) => false,
        );
      } else {
        setState(() {
          _hasError = true;
        });

        _shakeController.forward(from: 0);

        Messenger.show(
          context,
          response['message'] ?? 'Invalid or expired OTP',
          type: MessageType.error,
        );
      }
    } catch (e) {
      Messenger.show(
        context,
        'Something went wrong. Please try again.',
        type: MessageType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend || _isLoading) return;

    try {
      final response = await AuthService.registerAndSendOtp(
        name: widget.name,
        email: widget.email,
        phone: widget.phone,
        password: widget.password,
        device: widget.device,
        country: widget.country,
        state: widget.state,
      );

      if (!mounted) return;

      if (response['status'] == true) {
        String message = response['message'] ?? 'OTP resent successfully';

        if (response['otp'] != null) {
          message = '$message: ${response['otp']}';
        }

        Messenger.show(context, message, type: MessageType.success);

        _otpController.clear();

        setState(() {
          _hasError = false;
        });

        _startTimer();
      } else {
        Messenger.show(
          context,
          response['message'] ?? 'Failed to resend OTP',
          type: MessageType.error,
        );
      }
    } catch (e) {
      if (!mounted) return;

      Messenger.show(
        context,
        'Unable to resend OTP. Please try again.',
        type: MessageType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final PinTheme defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Color(0xFF202124),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _hasError ? Colors.redAccent : const Color(0xFFD9DEE8),
          width: 1.2,
        ),
      ),
    );

    final PinTheme focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: Colors.white,
        border: Border.all(color: const Color(0xFF0A6ED1), width: 1.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A6ED1).withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),

      body: Container(
        width: double.infinity,
        height: double.infinity,

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF3F8FF), Color(0xFFF5FFF7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),

            child: Column(
              children: [
                /// BACK BUTTON
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 19,
                        color: Color(0xFF202124),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                /// LOGO
                Container(
                  width: 90,
                  height: 90,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE4E9F0),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Verify your account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF202124),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'We sent a 6-digit verification code to',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  _maskEmail(widget.email),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: Color(0xFF0A6ED1),
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 26),

                /// MAIN CARD
                Container(
                  width: double.infinity,

                  padding: const EdgeInsets.fromLTRB(20, 26, 20, 24),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: const Color(0xFFEEF0F4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      /// OTP ICON
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0A6ED1), Color(0xFF6BCF2E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.lock_open_rounded,
                          color: Colors.white,
                          size: 31,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Enter OTP',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF252525),
                        ),
                      ),

                      const SizedBox(height: 7),

                      const Text(
                        'Enter the code below to continue',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF818793),
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// OTP INPUT
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
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
                          enabled: !_isLoading,
                          autofocus: true,

                          defaultPinTheme: defaultPinTheme,
                          focusedPinTheme: focusedPinTheme,
                          submittedPinTheme: focusedPinTheme,

                          showCursor: true,

                          onChanged: (value) {
                            if (_hasError) {
                              setState(() {
                                _hasError = false;
                              });
                            }
                          },

                          onCompleted: (_) {
                            FocusScope.of(context).unfocus();
                          },
                        ),
                      ),

                      const SizedBox(height: 26),

                      /// VERIFY BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: GradientButton(
                          text: _isLoading
                              ? 'Verifying...'
                              : 'Verify & Continue',

                          gradient: const LinearGradient(
                            colors: [Color(0xFF0A6ED1), Color(0xFF6BCF2E)],
                          ),

                          onPressed: _isLoading ? null : _handleVerifyOtp,
                        ),
                      ),

                      const SizedBox(height: 22),

                      /// RESEND AREA
                      const Text(
                        "Didn't receive the code?",
                        style: TextStyle(
                          color: Color(0xFF7B8190),
                          fontSize: 13.5,
                        ),
                      ),

                      const SizedBox(height: 6),

                      if (_canResend)
                        TextButton(
                          onPressed: _handleResendOtp,
                          child: const Text(
                            'Resend OTP',
                            style: TextStyle(
                              color: Color(0xFF0A6ED1),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7FB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Resend available in $_secondsRemaining s',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF737985),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                /// BOTTOM SECURITY NOTE
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 15,
                      color: Color(0xFF8B909C),
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Your verification code is secure and expires shortly',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8B909C),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
