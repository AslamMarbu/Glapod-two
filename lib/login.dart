import 'package:flutter/material.dart';
import 'otp_verification.dart';
import 'services/auth_service.dart';
import 'widgets.dart/gradient_button.dart';
import 'utils/ui_utils.dart';
import 'storage/local_storage_service.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    bool isLoggedIn = await LocalStorageService.isUserLoggedIn();

    if (isLoggedIn) {
      // User already logged in → go to Home screen
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  Future<void> _handleSendOtp() async {
    String phone = _phoneController.text.trim();

    if (phone.isEmpty || phone.length != 10) {

      Messenger.show(context,"Enter valid 10 digit mobile number",type: MessageType.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.sendOtp(phone);

      if (response['status'] == true) {
        Messenger.show(context,response['message'],type: MessageType.success);

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OtpVerificationPage(mobile: phone),
          ),
        );
      } else {
        Messenger.show(context,response['message'],type: MessageType.success);
      }
    } catch (e) {

      Messenger.show(context,"Something went wrong",type: MessageType.error);
    }

    setState(() => _isLoading = false);
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
                const SizedBox(height: 30),

                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                    labelText: 'Enter Phone Number',
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: GradientButton(
                    text: _isLoading ? "Sending..." : "Send OTP",
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A6ED1), Color(0xFF6BCF2E)],
                    ),
                    onPressed: _isLoading ? null : _handleSendOtp,
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
