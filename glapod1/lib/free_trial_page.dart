import 'package:flutter/material.dart';
import 'activate_continue_page.dart';
import 'widgets.dart/gradient_button.dart';

class FreeTrialPage extends StatelessWidget {
  const FreeTrialPage({super.key});

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
                width: 250,
                height: 100,
                padding: EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 94, 157, 209),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: const [
                    Text(
                      'Hi User,',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Free trial 7 days remaining',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),
              SizedBox(
                width: 300,
                height: 50,
                child: GradientButton(
                  text: 'Continue to App',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A6ED1), Color(0xFF6BCF2E)],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ActivateContinuePage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20.0),
              SizedBox(
                width: 300,
                height: 50,
                child: GradientButton(
                  text: 'Purchase Key',
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A6ED1), Color(0xFF6BCF2E)],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,

                      MaterialPageRoute(
                        builder: (context) => const FreeTrialPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
