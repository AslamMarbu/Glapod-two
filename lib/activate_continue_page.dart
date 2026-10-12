import 'package:flutter/material.dart';
import 'widgets.dart/gradient_button.dart';
import 'profile.dart';
import 'login.dart';
import 'package:Edmaster/utils/device_utils.dart';
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
  TextEditingController serialController = TextEditingController();
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
      final result = await AuthService.logout();

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
    final String serialNumber = serialController.text.trim();
    final String activationKey = codeController.text.trim();

    if (serialNumber.isEmpty) {
      Messenger.show(
        context,
        'Please enter serial number',
        type: MessageType.error,
      );
      return;
    }

    if (activationKey.isEmpty) {
      Messenger.show(
        context,
        'Please enter activation key',
        type: MessageType.error,
      );
      return;
    }

    _showConfirmationDialog(
      'Are you sure you want to activate your EdMaster subscription?',
    );
  }

  /// THE POPUP UI: Displays message and handles Step 2 confirmation
  void _showConfirmationDialog(String apiMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF8A24), Color(0xFFF16704)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF16704).withOpacity(0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Confirm Activation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF202124),
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  apiMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.55,
                    color: Colors.grey.shade600,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: GradientButton(
                    text: 'Yes, Activate',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF16704), Color(0xFFFF8A24)],
                    ),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _handleFinalActivation();
                    },
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
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
      // Automatically fetch device information
      final String device = await DeviceService.getDeviceId();

      final result = await AuthService.activatePurchaseKey(
        activationKey: codeController.text.trim(),
        serialNumber: serialController.text.trim(),
        deviceId: device,
      );

      if (mounted) {
        setState(() => isLoading = false);
      }

      if (result['success'] == true) {
        await LocalStorageService.saveLicenseStatus(true);

        if (!mounted) return;

        Messenger.show(context, result['message'], type: MessageType.success);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const ProfilePage(showSuccessMsg: true),
          ),
        );
      } else {
        if (!mounted) return;

        Messenger.show(context, result['message'], type: MessageType.error);
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);

        Messenger.show(context, "Activation failed", type: MessageType.error);
      }
    }
  }

  @override
  void dispose() {
    codeController.dispose();
    serialController.dispose();
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
                        color: Color.fromARGB(255, 232, 140, 75),
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
                            controller: serialController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Enter serial number',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: InputBorder.none,
                            ),
                          ),

                          const Divider(color: Colors.white54, thickness: 1),

                          TextField(
                            controller: codeController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Enter activation key',
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
                                colors: [
                                  Color(0xfff16704),
                                  Color.fromARGB(255, 249, 116, 22),
                                ],
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
                            color: Color(0xfff16704),
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
                            color: Color.fromARGB(255, 249, 116, 22),
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
