import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'widgets.dart/gradient_button.dart';
import 'utils/ui_utils.dart';
import 'storage/local_storage_service.dart';
import 'register_page.dart';
import 'free_trial.dart';
import 'student_dashboard.dart.';
import 'activate_continue_page.dart';
import 'profile.dart';
import 'forgot_password_page.dart';
import 'package:glapod/utils/device_utils.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  // Added state to track password visibility
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {});
  }

  Future<void> _handleLogin() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    // --- 1. Email Validations ---
    if (email.isEmpty) {
      Messenger.show(context, "Please enter your email", type: MessageType.error);
      return;
    }

    // Regex for standard email format
    bool isEmailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    if (!isEmailValid) {
      Messenger.show(context, "Please enter a valid email address", type: MessageType.error);
      return;
    }

    // --- 2. Password Validations ---
    if (password.isEmpty) {
      Messenger.show(context, "Please enter your password", type: MessageType.error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String deviceId = await DeviceService.getDeviceId();
      final response = await AuthService.loginAuth(
        email: email,
        password: password,
        deviceId: deviceId
      );

      if (response['status'] == true) {
        final student = response['student'];

        await LocalStorageService.saveUserSession(
          token: response['token'],
          studentData: student,
        );

        final LicenseStatus status = await LocalStorageService.getLicenseStatus();

        if (!mounted) return;

        Widget nextPage;
        switch (status) {
          case LicenseStatus.needProfileUpdate:
            nextPage = const ProfilePage();
            break;
          case LicenseStatus.activated:
            nextPage = const StudentDashboardPage();
            break;
          case LicenseStatus.trialing:
            nextPage = const FreeTrialPage();
            break;
          case LicenseStatus.expired:
          case LicenseStatus.trialExpired:
          default:
            nextPage = const ActivateContinuePage();
            break;
        }

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => nextPage),
              (route) => false,
        );
      } else {
        Messenger.show(context, response['message'] ?? "Login failed", type: MessageType.error);
      }
    } catch (e) {
      debugPrint("Login Error: $e");
      Messenger.show(context, "Something went wrong. Please try again.", type: MessageType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    /// LOGO + TITLE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/logoo.png',
                          height: 60,
                        ),
                        const SizedBox(width: 2), const Text(
                        'EdMaster',
                        style: TextStyle(
                        fontSize: 40,
                          fontWeight: FontWeight.bold,
                        color: Colors.black,
                          ),
                         ),
                      ],
                    ),

                    const SizedBox(height: 25),

                    /// WELCOME TEXT
                    const Text(
                      'Welcome to Glapod',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkGrey,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Learn better with expert curated content',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkGrey.withOpacity(0.7),
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// EMAIL FIELD
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Enter your email',
                        hintStyle: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// PASSWORD FIELD
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Enter your password',
                        hintStyle: TextStyle(
                          color: Colors.black.withOpacity(0.6),
                          fontSize: 14,
                        ),
                        // Black eye toggle added here
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppColors.darkGrey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: GradientButton(
                        text: _isLoading ? "Loading..." : "Login",
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0A6ED1), Color(0xFF6BCF2E)],
                        ),
                        onPressed: _isLoading ? null : _handleLogin,
                      ),
                    ),

                    const SizedBox(height: 18),

                    /// REGISTER TEXT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Not registered? ",
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.darkGrey,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscurePassword = true;
                              _emailController.clear();
                              _passwordController.clear();
                            });

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Register",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    /// REGISTER TEXT
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _obscurePassword = true;
                              _emailController.clear();
                              _passwordController.clear();
                            });

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Forgot Password",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.green,
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
        ],
      ),
    );
  }
}