import 'package:flutter/material.dart';
import 'login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Glapod',
      theme: ThemeData(
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color.fromARGB(255, 0, 0, 0),
          onPrimary: Color.fromARGB(
            255,
            255,
            255,
            255,
          ), // Text/icons *on* primary color
          secondary: Color.fromARGB(255, 28, 192, 178), // Your secondary color
          onSecondary: Color.fromARGB(255, 134, 67, 67),

          // Text/icons *on* secondary color
          error: Color(0xFFB00020),
          onError: Color(0xFFFFFFFF),
          surface: Color(0xFFFFFFFF),
          outline: Color.fromARGB(
            255,
            206,
            204,
            204,
          ), // Background color for cards, sheets, etc.
          onSurface: Color(0xFF000000), // Text/icons *on* surface color
          // Add other Material 3 roles like tertiary, background, etc.
        ),
        useMaterial3: true,
      ),

      home: const MyHomePage(),
    );
  }
}
