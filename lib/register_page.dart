import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets.dart/gradient_button.dart'; // Adjust path if necessary
import '../utils/ui_utils.dart';
import 'otp_verification.dart';
import '../utils/device_utils.dart';

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
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // --- NEW STATE FIELDS ---
  String? _selectedCountry;
  String? _selectedState;

  final List<String> _countries = [
    "India", "USA", "UK", "Canada", "Australia",
    "Germany", "France", "UAE", "Singapore", "Japan",
    "Brazil", "South Africa", "Italy", "Spain", "Mexico"
  ];

  final List<String> _indianStates = [
    "Andhra Pradesh", "Arunachal Pradesh", "Assam", "Bihar", "Chhattisgarh",
    "Goa", "Gujarat", "Haryana", "Himachal Pradesh", "Jharkhand", "Karnataka",
    "Kerala", "Madhya Pradesh", "Maharashtra", "Manipur", "Meghalaya", "Mizoram",
    "Nagaland", "Odisha", "Punjab", "Rajasthan", "Sikkim", "Tamil Nadu",
    "Telangana", "Tripura", "Uttar Pradesh", "Uttarakhand", "West Bengal"
  ];

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

    // Validation
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

    // Country & State Validation
    if (_selectedCountry == null) {
      Messenger.show(context, "Please select your country", type: MessageType.error);
      return;
    }
    if (_selectedCountry == "India" && _selectedState == null) {
      Messenger.show(context, "Please select your state", type: MessageType.error);
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
        country: _selectedCountry ?? "",
        state: _selectedState ?? "", // Default to N/A for non-India
      );

      if (response['status'] == true) {
        String displayMsg = response['message'] ?? 'OTP sent successfully';
        if (response['otp'] != null) {
          displayMsg = "$displayMsg: ${response['otp']}";
        }

        Messenger.show(context, displayMsg, type: MessageType.success, autoHide: false);
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationPage(
                name: name,
                email: email,
                phone: phone,
                password: password,
                device: device,
                country: _selectedCountry!, // Pass it forward
                state: _selectedState ?? "", // Pass it forward
                // Ensure OtpVerificationPage accepts country/state if needed
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          fillColor: Colors.white,
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

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: hintStyle),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE5F3FF), Color(0xFFE9FFE9)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -400, left: 0, right: -60, bottom: 490,
            child: Image.asset("assets/images/bot.jpeg", width: MediaQuery.of(context).size.width, fit: BoxFit.cover),
          ),
          Positioned(
            bottom: -60, left: -60, right: -40, top: 600,
            child: Image.asset("assets/images/top.jpeg", width: MediaQuery.of(context).size.width * 1.2, fit: BoxFit.fill),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/logoo.png', height: 45),
                        const SizedBox(width: 8),
                        const Text('Glapod', style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 25),
                    const Text('Create Account', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Register to start learning', style: TextStyle(fontSize: 15, color: Colors.black54)),
                    const SizedBox(height: 25),

                    _buildTextField(controller: _nameController, hint: 'Enter your name'),
                    const SizedBox(height: 15),
                    _buildTextField(controller: _emailController, hint: 'Enter your email', keyboardType: TextInputType.emailAddress),
                    const SizedBox(height: 15),
                    _buildTextField(controller: _phoneController, hint: 'Enter phone number', keyboardType: TextInputType.phone),
                    const SizedBox(height: 15),

                    // --- COUNTRY DROPDOWN ---
                    _buildDropdown(
                      hint: 'Select Country',
                      value: _selectedCountry,
                      items: _countries,
                      onChanged: (val) {
                        setState(() {
                          _selectedCountry = val;
                          _selectedState = null; // Clear state if country changes
                        });
                      },
                    ),

                    // --- CONDITIONAL STATE DROPDOWN ---
                    if (_selectedCountry == "India") ...[
                      const SizedBox(height: 15),
                      _buildDropdown(
                        hint: 'Select State',
                        value: _selectedState,
                        items: _indianStates,
                        onChanged: (val) => setState(() => _selectedState = val),
                      ),
                    ],

                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _passwordController,
                      hint: 'Enter password',
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      hint: 'Confirm password',
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
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
                          child: const Text("Log in", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF6BCF2E))),
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