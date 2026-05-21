// import 'package:flutter/material.dart';
// import 'otp_verification.dart';
// import 'services/auth_service.dart';
// import 'widgets.dart/gradient_button.dart';
// import 'utils/ui_utils.dart';
// import 'storage/local_storage_service.dart';
// import 'register_page.dart';
// import 'free_trial.dart';
//
// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key});
//
//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }
//
// class _MyHomePageState extends State<MyHomePage> {
//
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//
//   bool _isLoading = false;
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   @override
//   void initState() {
//     super.initState();
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _checkLogin();
//     });
//   }
//
//   Future<void> _checkLogin() async {
//     bool isLoggedIn = await LocalStorageService.isUserLoggedIn();
//
//     if (isLoggedIn && mounted) {
//       Navigator.pushReplacementNamed(context, '/dashboard');
//     }
//   }
//
//   Future<void> _handleLogin() async {
//
//     String email = _emailController.text.trim();
//     String password = _passwordController.text.trim();
//
//     if (email.isEmpty || password.isEmpty) {
//
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => FreeTrialPage(),
//         ),
//       );
//
//       Messenger.show(context, "Please enter email and password",
//           type: MessageType.error);
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//
//       final response = await AuthService.sendOtp(email);
//
//       if (response['status'] == true) {
//
//         Messenger.show(context, response['message'],
//             type: MessageType.success);
//
//
//
//       } else {
//
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => OtpVerificationPage(mobile: email),
//           ),
//         );
//
//         //Messenger.show(context, response['message'],type: MessageType.error);
//
//       }
//
//     } catch (e) {
//
//       Messenger.show(context, "Something went wrong",
//           type: MessageType.error);
//
//     }
//
//     if (mounted) {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//
//     return Scaffold(
//
//       body: Stack(
//         children: [
//
//           /// BACKGROUND GRADIENT
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Color(0xFFE5F3FF), Color(0xFFE9FFE9)],
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//               ),
//             ),
//           ),
//
//           /// TOP WAVE
//           Positioned(
//             top: -400,
//             left: 0,
//             right: -60,
//             bottom: 490,
//             child: Image.asset(
//               "assets/images/bot.jpeg",
//               width: MediaQuery.of(context).size.width,
//               fit: BoxFit.cover,
//             ),
//           ),
//
//           /// BOTTOM WAVE
//           Positioned(
//             bottom: -60,
//             left: -60,
//             right: -40,
//             top: 600,
//             child: Image.asset(
//               "assets/images/top.jpeg",
//               width: MediaQuery.of(context).size.width * 1.2,
//               fit: BoxFit.fill,
//             ),
//           ),
//
//           /// MAIN CONTENT
//           SafeArea(
//             child: Center(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(40),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//
//                     /// LOGO + TITLE
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Image.asset(
//                           'assets/images/logo.png',
//                           height: 45,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text(
//                           'Glapod',
//                           style: TextStyle(
//                             fontSize: 40,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black,
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     const SizedBox(height: 25),
//
//                     /// WELCOME TEXT
//                     const Text(
//                       'Welcome to Glapod',
//                       style: TextStyle(
//                         fontSize: 26,
//                         fontWeight: FontWeight.bold,
//                         color: AppColors.darkGrey,
//                       ),
//                     ),
//
//                     const SizedBox(height: 8),
//
//                     Text(
//                       'Learn better with expert curated content',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: AppColors.darkGrey.withOpacity(0.7),
//                       ),
//                     ),
//
//                     const SizedBox(height: 15),
//
//                     /// EMAIL FIELD
//                     TextField(
//                       controller: _emailController,
//                       keyboardType: TextInputType.emailAddress,
//                       decoration: InputDecoration(
//                         filled: true,
//                         fillColor: Colors.white,
//                         hintText: 'Enter your email',
//
//                         hintStyle: TextStyle(
//                           color: Colors.black.withOpacity(0.6),
//                           fontSize: 14,
//                         ),
//
//                         prefixIcon: const Icon(
//                           Icons.email_outlined,
//                           color: Color(0xFF0A6ED1),
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(14),
//                           borderSide: BorderSide.none,
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     /// PASSWORD FIELD
//                     TextField(
//                       controller: _passwordController,
//                       obscureText: true,
//                       decoration: InputDecoration(
//                         filled: true,
//                         fillColor: Colors.white,
//                         hintText: 'Enter your password',
//
//                         hintStyle: TextStyle(
//                           color: Colors.black.withOpacity(0.6),
//                           fontSize: 14,
//                         ),
//
//                         prefixIcon: const Icon(
//                           Icons.lock_outline,
//                           color: Color(0xFF0A6ED1),
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(14),
//                           borderSide: BorderSide.none,
//                         ),
//                       ),
//                     ),
//
//                     const SizedBox(height: 20),
//
//                     /// LOGIN BUTTON
//                     SizedBox(
//                       width: double.infinity,
//                       height: 55,
//                       child: GradientButton(
//                         text: _isLoading ? "Loading..." : "Login",
//                         gradient: const LinearGradient(
//                           colors: [Color(0xFF0A6ED1), Color(0xFF6BCF2E)],
//                         ),
//                         onPressed: _isLoading ? null : _handleLogin,
//                       ),
//                     ),
//
//                     const SizedBox(height: 18),
//
//                     /// REGISTER TEXT
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const Text(
//                           "Not registered? ",
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: AppColors.darkGrey,
//                           ),
//                         ),
//                         GestureDetector(
//                           onTap: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => const RegisterPage(),
//                               ),
//                             );
//                           },
//                           child: const Text(
//                             "Register",
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: AppColors.green,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }