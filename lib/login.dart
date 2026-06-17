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
      Messenger.show(
        context,
        "Please enter your email",
        type: MessageType.error,
      );
      return;
    }

    // Regex for standard email format
    bool isEmailValid = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(email);
    if (!isEmailValid) {
      Messenger.show(
        context,
        "Please enter a valid email address",
        type: MessageType.error,
      );
      return;
    }

    // --- 2. Password Validations ---
    if (password.isEmpty) {
      Messenger.show(
        context,
        "Please enter your password",
        type: MessageType.error,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String deviceId = await DeviceService.getDeviceId();
      final response = await AuthService.loginAuth(
        email: email,
        password: password,
        deviceId: deviceId,
      );

      if (response['status'] == true) {
        final student = response['student'];

        await LocalStorageService.saveUserSession(
          token: response['token'],
          studentData: student,
        );

        final LicenseStatus status =
            await LocalStorageService.getLicenseStatus();

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
        Messenger.show(
          context,
          response['message'] ?? "Login failed",
          type: MessageType.error,
        );
      }
    } catch (e) {
      debugPrint("Login Error: $e");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/LBG.png", fit: BoxFit.cover),
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
                        color: Color.fromARGB(255, 2, 2, 2),
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// WELCOME TEXT
                    // const Text(
                    //   'Welcome to Glapod',
                    //   style: TextStyle(
                    //     fontSize: 26,
                    //     fontWeight: FontWeight.bold,
                    //     color: AppColors.darkGrey,
                    //   ),
                    // ),
                    Text(
                      'Learn better with expert curated content',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.darkGrey.withOpacity(0.7),
                      ),
                    ),

                    const SizedBox(height: 35),

                    Container(
                      width: MediaQuery.of(context).size.width * 0.9,
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
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: const Color.fromARGB(
                                255,
                                255,
                                255,
                                255,
                              ),
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
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
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
                                  fontSize: 14,
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
                                      builder: (context) =>
                                          const RegisterPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Register",
                                  style: TextStyle(
                                    fontSize: 15,
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
                                      builder: (context) =>
                                          const ForgotPasswordPage(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Forgot Password",
                                  style: TextStyle(
                                    fontSize: 15,
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
