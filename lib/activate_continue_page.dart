import 'package:flutter/material.dart';
import 'widgets.dart/gradient_button.dart';
import 'profile.dart';


class ActivateContinuePage extends StatefulWidget {
  const ActivateContinuePage({super.key});

  @override
  State<ActivateContinuePage> createState() => _ActivateContinuePageState();
}

class _ActivateContinuePageState extends State<ActivateContinuePage> {
  bool isLoading = false;
  String errorMessage = '';
  TextEditingController codeController = TextEditingController();

  Future<void> activateKey() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    await Future.delayed(const Duration(seconds: 2));

    if (codeController.text == '+') {
      setState(() {
        isLoading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'Invalid purchase code';
      });
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 300,
                height: 150,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 94, 157, 209),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Please enter key to continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        hintText: 'Enter purchase code',
                        hintStyle: TextStyle(
                          color: Color.fromARGB(153, 0, 0, 0),
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: 300,
                height: 50,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : GradientButton(
                        text: 'Activate & Continue',
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0A6ED1), Color(0xFF6BCF2E)],
                        ),
                        onPressed: activateKey,
                      ),
              ),

              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 20),

              const Text(
                'Click here to go back',
                style: TextStyle(
                  color: Color.fromARGB(255, 66, 180, 70),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
