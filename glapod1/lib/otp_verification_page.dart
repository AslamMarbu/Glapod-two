import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'free_trial_page.dart';
import 'widgets.dart/gradient_button.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose(); // always dispose controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.all(50.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Glapod',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 30.0),

                Text(
                  'Verify OTP',
                  style: TextStyle(
                    fontSize: 35,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 10.0),

                const Text(
                  'Code sent to +91',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color.fromARGB(255, 225, 225, 225),
                  ),
                ),

                const SizedBox(height: 20.0),

                Pinput(
                  controller: _otpController,
                  length: 6,
                  defaultPinTheme: PinTheme(
                    width: 56,
                    height: 56,
                    textStyle: const TextStyle(fontSize: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),

                const SizedBox(height: 20.0),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: GradientButton(
                    text: 'Verify OTP',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A6ED1), Color(0xFF6BCF2E)],
                    ),
                    onPressed: () {
                      String otp = _otpController.text;

                      if (otp.length == 6) {
                        print("Entered OTP: $otp");

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FreeTrialPage(),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Please enter 6 digit OTP"),
                          ),
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 30.0),

                GestureDetector(
                  onTap: () {
                    print("Resend OTP clicked");
                  },
                  child: const Text(
                    'Resend OTP',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
