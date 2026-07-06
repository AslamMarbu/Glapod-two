import 'package:flutter/material.dart';
import 'widgets.dart/gradient_button.dart';
import 'profile.dart';
import 'login.dart';
import 'package:glapod/utils/device_utils.dart';
import 'services/auth_service.dart';
import 'utils/ui_utils.dart';
import 'storage/local_storage_service.dart';

class ActivateContinuePage extends StatefulWidget {
  const ActivateContinuePage({super.key});

  @override
  State<ActivateContinuePage> createState() => _ActivateContinuePageState();
}

class _ActivateContinuePageState extends State<ActivateContinuePage> {
  bool isLoading = false;
  TextEditingController codeController = TextEditingController();
  bool isUserRegistered = false;
  bool isLicenseExpired = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final studentData = await LocalStorageService.getStudent();
    final status = await LocalStorageService.getLicenseStatus();
    if (mounted) {
      setState(() {
        isUserRegistered = studentData != null;
        String statusStr = status.toString();
        isLicenseExpired =
            statusStr.contains("expired") || statusStr.contains("trialExpired");
      });
    }
  }

  void _handleLogout(BuildContext context) async {
    try {
      String deviceId = await DeviceService.getDeviceId();

debugPrint("LOGOUT DEVICE ID => $deviceId");

final result = await AuthService.logout(
  deviceId: deviceId,
);

debugPrint("LOGOUT RESPONSE => $result");
    } catch (e) {
      debugPrint("LOGOUT ERROR => $e");
    }

    await LocalStorageService.logOut();

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyHomePage()),
        (route) => false,
      );
    }
  }

  /// FLOW STEP 1: Call API to verify key and get the popup message
  Future<void> _handleInitialCheck() async {
    final String code = codeController.text.trim();
    if (code.isEmpty) {
      Messenger.show(
        context,
        'Please enter purchase code',
        type: MessageType.error,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String device = await DeviceService.getDeviceId();
      final result = await AuthService.enterPurchaseKey(
        key: code,
        deviceId: device,
      );

      setState(() => isLoading = false);

      if (result['success'] == true) {
        // Step 1 Success: Show the popup with the message from the API
        _showConfirmationDialog(result['message']);
      } else {
        // Step 1 Fail: Show error message
        Messenger.show(context, result['message'], type: MessageType.error);
      }
    } catch (e) {
      setState(() => isLoading = false);
      Messenger.show(context, "Connection error", type: MessageType.error);
    }
  }

  /// THE POPUP UI: Displays message and handles Step 2 confirmation
  void _showConfirmationDialog(String apiMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          contentPadding: EdgeInsets.zero,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          content: Container(
            width: double.maxFinite,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF6BCF2E),
                width: 2,
              ), // Green Border
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1B75BB).withOpacity(0.1),
                      const Color(0xFF6BCF2E).withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Confirm Activation",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF1B75BB),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      apiMessage, // MESSAGE FROM API
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: GradientButton(
                        text: 'Yes, Continue',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0A6ED1), Color(0xFF6BCF2E)],
                        ),
                        onPressed: () {
                          Navigator.pop(context); // Close Popup
                          _handleFinalActivation(); // Start Step 2
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// FLOW STEP 2: Finalize activation when user clicks "Yes"
  Future<void> _handleFinalActivation() async {
    setState(() => isLoading = true);

    try {
      String device = await DeviceService.getDeviceId();
      final result = await AuthService.activatePurchaseKey(
        key: codeController.text.trim(),
        deviceId: device,
      );

      setState(() => isLoading = false);

      if (result['success'] == true) {
        await LocalStorageService.saveLicenseStatus(true);
        Messenger.show(context, result['message'], type: MessageType.success);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfilePage(showSuccessMsg: true),
          ),
        );
      } else {
        Messenger.show(context, result['message'], type: MessageType.error);
      }
    } catch (e) {
      setState(() => isLoading = false);
      Messenger.show(context, "Activation failed", type: MessageType.error);
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
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
            top: -400,
            left: 0,
            right: -60,
            bottom: 490,
            child: Image.asset("assets/images/bot.jpeg", fit: BoxFit.cover),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            right: -40,
            top: 600,
            child: Image.asset("assets/images/top.jpeg", fit: BoxFit.fill),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 94, 157, 209),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Please enter key to continue',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: codeController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Enter purchase code',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                          ),
                          const Divider(color: Colors.white54, thickness: 1),
                        ],
                      ),
                    ),
                    const SizedBox(height: 35),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : GradientButton(
                              text: 'Activate & Continue',
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A6ED1), Color(0xFF6BCF2E)],
                              ),
                              onPressed: _handleInitialCheck, // STARTS FLOW
                            ),
                    ),
                    const SizedBox(height: 30),
                    if (isLicenseExpired)
                      TextButton(
                        onPressed: () => _handleLogout(context),
                        child: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Color(0xFF1B75BB),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      )
                    else
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Click here to go back',
                          style: TextStyle(
                            color: Color.fromARGB(255, 66, 180, 70),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
