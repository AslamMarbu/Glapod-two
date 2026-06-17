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
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // --- NEW STATE FIELDS ---
  String? _selectedCountry;
  String? _selectedState;

  final List<String> _countries = [
    "India",
    "USA",
    "UK",
    "Canada",
    "Australia",
    "Germany",
    "France",
    "UAE",
    "Singapore",
    "Japan",
    "Brazil",
    "South Africa",
    "Italy",
    "Spain",
    "Mexico",
  ];

  final List<String> _indianStates = [
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
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
      Messenger.show(
        context,
        "Please enter your name",
        type: MessageType.error,
      );
      return;
    }
    if (email.isEmpty ||
        !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      Messenger.show(
        context,
        "Please enter a valid email",
        type: MessageType.error,
      );
      return;
    }
    if (phone.length != 10) {
      Messenger.show(
        context,
        "Enter a valid 10-digit phone number",
        type: MessageType.error,
      );
      return;
    }

    // Country & State Validation
    if (_selectedCountry == null) {
      Messenger.show(
        context,
        "Please select your country",
        type: MessageType.error,
      );
      return;
    }
    if (_selectedCountry == "India" && _selectedState == null) {
      Messenger.show(
        context,
        "Please select your state",
        type: MessageType.error,
      );
      return;
    }

    if (password.length < 8) {
      Messenger.show(
        context,
        "Password must be at least 8 characters",
        type: MessageType.error,
      );
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

        Messenger.show(
          context,
          displayMsg,
          type: MessageType.success,
          autoHide: false,
        );
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
        Messenger.show(
          context,
          response['message']?.toString() ?? "Registration failed",
          type: MessageType.error,
        );
      }
    } catch (e) {
      Messenger.show(
        context,
        "Network error. Please try again.",
        type: MessageType.error,
      );
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
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: hint,
        hintStyle: TextStyle(color: Colors.black.withOpacity(.6), fontSize: 14),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
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
          /// SAME BACKGROUND AS LOGIN PAGE
          Positioned.fill(
            child: Image.asset("assets/images/LBG.png", fit: BoxFit.cover),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    /// LOGO
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.15),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Image.asset(
                          "assets/images/logo.png",
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      "EdMaster",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Create your account and start learning",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(.6),
                      ),
                    ),

                    const SizedBox(height: 25),

                    /// REGISTER CARD
                    Container(
                      width: MediaQuery.of(context).size.width * .9,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.08),
                            blurRadius: 25,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            hint: 'Enter your name',
                          ),

                          const SizedBox(height: 15),

                          _buildTextField(
                            controller: _emailController,
                            hint: 'Enter your email',
                            keyboardType: TextInputType.emailAddress,
                          ),

                          const SizedBox(height: 15),

                          _buildTextField(
                            controller: _phoneController,
                            hint: 'Enter phone number',
                            keyboardType: TextInputType.phone,
                          ),

                          const SizedBox(height: 15),

                          _buildDropdown(
                            hint: 'Select Country',
                            value: _selectedCountry,
                            items: _countries,
                            onChanged: (val) {
                              setState(() {
                                _selectedCountry = val;
                                _selectedState = null;
                              });
                            },
                          ),

                          if (_selectedCountry == "India") ...[
                            const SizedBox(height: 15),
                            _buildDropdown(
                              hint: 'Select State',
                              value: _selectedState,
                              items: _indianStates,
                              onChanged: (val) {
                                setState(() {
                                  _selectedState = val;
                                });
                              },
                            ),
                          ],

                          const SizedBox(height: 15),

                          _buildTextField(
                            controller: _passwordController,
                            hint: 'Enter password',
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 15),

                          _buildTextField(
                            controller: _confirmPasswordController,
                            hint: 'Confirm password',
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 25),

                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: GradientButton(
                              text: _isLoading ? "Loading..." : "Register",
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A6ED1), Color(0xFF6BCF2E)],
                              ),
                              onPressed: _isLoading ? null : _handleRegister,
                            ),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account? ",
                                style: TextStyle(color: Colors.black54),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  "Login",
                                  style: TextStyle(
                                    color: Color(0xFF6BCF2E),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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
