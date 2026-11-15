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
        'Please enter licence key',
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
                const Text(
                  'Confirm Activation',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
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
                      colors: [Color(0xFF2F80ED), Color(0xFFFF8A24)],
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
      // Retrieve saved student details
      final studentData = await LocalStorageService.getStudent();

      if (studentData == null) {
        throw Exception('Student details not found');
      }

      final String name = studentData['name']?.toString() ?? '';

      final String mobile =
          (studentData['phone'] ?? studentData['mobile'])?.toString() ?? '';

      final String email =
          (studentData['mail_id'] ?? studentData['email'])?.toString() ?? '';

      final String country = studentData['country']?.toString() ?? '';
      final String state = studentData['state']?.toString() ?? '';

      debugPrint('ACTIVATION STUDENT DATA => $studentData');
      debugPrint('ACTIVATION EMAIL => $email');
      debugPrint('ACTIVATION COUNTRY => $country');

      if (email.trim().isEmpty || country.trim().isEmpty) {
        throw Exception(
          'Email or country information is missing. Please check your profile.',
        );
      }

      // Automatically fetch device information
      final String device = await DeviceService.getDeviceId();

      // Send activation request
      final result = await AuthService.activatePurchaseKey(
        activationKey: codeController.text.trim(),
        serialNumber: serialController.text.trim(),
        name: name,
        mobile: mobile,
        email: email,
        country: country,
        state: country.toLowerCase() == 'india' ? state : null,
        deviceInfo: device,
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

        Messenger.show(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          type: MessageType.error,
        );
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
    const navy = Color(0xFF1F2937);
    const blue = Color(0xFF2F80ED);
    const green = Color(0xFF27AE60);
    const orange = Color(0xFFFF7008);
    const muted = Color(0xFF64748B);

    final screenWidth = MediaQuery.sizeOf(context).width;

    InputDecoration inputDecoration({
      required String hint,
      required IconData icon,
    }) {
      return InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        prefixIcon: Icon(icon, color: muted, size: 21),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 19,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: blue, width: 1.6),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F3),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Orange and white abstract background image
          Image.asset(
            'assets/images/activation_page_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),

          // Responsive page content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth < 360 ? 16 : 22,
                    vertical: 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 8),

                          // EdMaster logo
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
                            child: ClipOval(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(3, 3, 3, 6),
                                child: Image.asset(
                                  'assets/images/logo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // TITLE
                          const Text(
                            'Activate EdMaster',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),

                          const SizedBox(height: 10),

                          // SUBTITLE
                          Text(
                            'YOUR DIGITAL KNOWLEDGE SPACE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withOpacity(0.85),
                            ),
                          ),

                          const SizedBox(height: 35),

                          // White activation card
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(
                              screenWidth < 360 ? 20 : 24,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.97),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 28,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Serial number',
                                  style: TextStyle(
                                    color: navy,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                TextField(
                                  controller: serialController,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(
                                    color: navy,
                                    fontSize: 15,
                                  ),
                                  decoration: inputDecoration(
                                    hint: 'Enter serial number',
                                    icon: Icons.confirmation_number_outlined,
                                  ),
                                ),

                                const SizedBox(height: 26),

                                const Text(
                                  'Licence key',
                                  style: TextStyle(
                                    color: navy,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                TextField(
                                  controller: codeController,
                                  textInputAction: TextInputAction.done,
                                  autocorrect: false,
                                  enableSuggestions: false,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  style: const TextStyle(
                                    color: navy,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                  decoration: inputDecoration(
                                    hint: 'Enter licence key',
                                    icon: Icons.key_rounded,
                                  ),
                                  onSubmitted: (_) => _handleInitialCheck(),
                                ),

                                const SizedBox(height: 28),

                                // Blue-to-green activation button
                                SizedBox(
                                  width: double.infinity,
                                  height: 58,
                                  child: isLoading
                                      ? const Center(
                                          child: CircularProgressIndicator(
                                            color: blue,
                                          ),
                                        )
                                      : GradientButton(
                                          text: 'Activate & Continue',
                                          gradient: const LinearGradient(
                                            colors: [blue, green],
                                          ),
                                          onPressed: _handleInitialCheck,
                                        ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Logout or Go Back button
                          if (isLicenseExpired)
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () => _handleLogout(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: orange,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 36,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                child: const Text(
                                  'LOGOUT',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            )
                          else
                            TextButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Go back'),
                              style: TextButton.styleFrom(
                                foregroundColor: navy,
                              ),
                            ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
