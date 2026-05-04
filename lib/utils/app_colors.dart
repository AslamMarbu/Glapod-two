import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF1B75BB);
  static const Color primaryGreen = Color(0xFF6BCF2E);
  static const Color logoGrey = Color(0xFF333333);
  static const Color textLightBlack = Color(0xFF424242);
  static const Color textHeadingBlack = Color(0xFF565C63);
  static const Color textBodyGrey = Color(0xFF666666);

  // FIX 1: Use Hex code for Grey so 'static const' works
  static const Color textSubtitle = Color(0xFF9E9E9E);
  static const Color lightPinkBackground = Color(0xFFFFEBEE);
  static const Color deepPurple = Color(0xFF9575CD);

  // Action Colors
  static const Color actionBlueStart = Color(0xFF4FACFE);
  static const Color actionBlueEnd = Color(0xFF00F2FE);
  static const Color actionBlue = Color(0xFF4FACFE);

  // UI Backgrounds
  static const Color mintBackground = Color(0xFFF1FAF2);
  static const Color mintBackgroundDark = Color(0xFFDAF5DD);
  static const Color cardWhite = Colors.white;

  // Gradients
  static const LinearGradient mainGradient = LinearGradient(
    colors: [primaryBlue, primaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient actionGradient = LinearGradient(
    colors: [actionBlueStart, actionBlueEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bgMintGradient = LinearGradient(
    colors: [mintBackground, mintBackgroundDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
} // This is the ONLY closing brace that should be here