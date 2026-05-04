import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'widgets.dart/gradient_button.dart';
import 'utils/ui_utils.dart';
import 'login.dart';
import 'otp_verification.dart';
import 'package:glapod/utils/device_utils.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  // State for password visibility toggles
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final TextStyle hintStyle = const TextStyle(
    color: Colors.black54,
    fontSize: 14,
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();
    final String phone = _phoneController.text.trim();
    final String password = _passwordController.text.trim();
    final String cpassword = _confirmPasswordController.text.trim();
    String device = await DeviceService.getDeviceId();

    if (name.isEmpty) {
      Messenger.show(context, "Please enter your name", type: MessageType.error);
      return;
    }
    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      Messenger.show(context, "Please enter a valid email", type: MessageType.error);
      return;
    }
    if (phone.length != 10) {
      Messenger.show(context, "Enter a valid 10-digit phone number", type: MessageType.error);
      return;
    }
    if (password.length < 8) {
      Messenger.show(context, "Password must be at least 8 characters", type: MessageType.error);
      return;
    }
    if (password != cpassword) {
      Messenger.show(context, "Password mismatch", type: MessageType.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.registerAndSendOtp(
        name: name,
        email: email,
        phone: phone,
        password: password,
        device: device,
      );

      if (response['status'] == true) {
        String displayMsg = response['message'] ?? 'OTP sent successfully';
        if (response['otp'] != null) {
          displayMsg = "$displayMsg: ${response['otp']}";
        }

        Messenger.show(context, displayMsg, type: MessageType.success,autoHide:false);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationPage(
                name: name, email: email, phone: phone, password: password, device: device,
              ),
            ),
          );
        }
      } else {
        Messenger.show(context, response['message']?.toString() ?? "Registration failed", type: MessageType.error);
      }
    } catch (e) {
      Messenger.show(context, "Network error. Please try again.", type: MessageType.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper for TextFields (No prefix icons, includes content padding)
  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      // Force a solid white background with a shadow to "punch through" the image overlap
      decoration: BoxDecoration(
        color: Colors.white, // Solid white
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white, // Redundant but safe
          hintText: hint,
          hintStyle: hintStyle,
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// BACKGROUND GRADIENT (Matches Login)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE5F3FF), Color(0xFFE9FFE9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          /// TOP WAVE (Matches Login - Uses bot.jpeg)
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

          /// BOTTOM WAVE (Matches Login - Uses top.jpeg)
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
                    /// LOGO + TITLE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/logoo.png', height: 45),
                        const SizedBox(width: 8),
                        const Text(
                          'Glapod',
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    const SizedBox(height: 25),
                    const Text(
                      'Create Account',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Register to start learning',
                      style: TextStyle(fontSize: 15, color: Colors.black54),
                    ),
                    const SizedBox(height: 25),

                    _buildTextField(controller: _nameController, hint: 'Enter your name'),
                    const SizedBox(height: 15),
                    _buildTextField(controller: _emailController, hint: 'Enter your email', keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 15),
                    _buildTextField(controller: _phoneController, hint: 'Enter phone number', keyboardType: TextInputType.phone),
                    const SizedBox(height: 15),

                    // Password with Eye Icon
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Enter password',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.darkGrey
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Confirm Password with Eye Icon
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hint: 'Confirm password',
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.darkGrey
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),

                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity, height: 55,
                      child: GradientButton(
                        text: _isLoading ? "Loading..." : "Register",
                        gradient: const LinearGradient(colors: [Color(0xFF0A6ED1), Color(0xFF6BCF2E)]),
                        onPressed: _isLoading ? null : _handleRegister,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? ", style: TextStyle(fontSize: 16, color: Colors.black54)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            "Log in",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6BCF2E)),
                          ),
                        ),
                      ],
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