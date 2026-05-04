import 'package:flutter/material.dart';

/// APP COLORS
class AppColors {
  static const Color darkGrey = Color(0xFF2D2D2D);
  static const Color green = Color(0xFF6BCF2E);
}

/// MESSAGE TYPES
enum MessageType { success, error, info }

/// SNACKBAR MESSENGER
class Messenger {
  static void show(BuildContext context, String message,
      {MessageType type = MessageType.info, bool autoHide = true}) { // Added autoHide parameter

    Color backgroundColor;
    IconData icon;

    switch (type) {
      case MessageType.success:
        backgroundColor = Colors.green;
        icon = Icons.check_circle;
        break;

      case MessageType.error:
        backgroundColor = Colors.red;
        icon = Icons.error;
        break;

      case MessageType.info:
      default:
        backgroundColor = Colors.blueGrey;
        icon = Icons.info;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        // If autoHide is true, it hides after 4 seconds.
        // If false, it stays for 365 days (effectively persistent).
        duration: autoHide ? const Duration(seconds: 4) : const Duration(days: 365),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        // Adding a close action automatically if it doesn't auto-hide
        action: autoHide ? null : SnackBarAction(
          label: 'CLOSE',
          textColor: Colors.white,
          onPressed: () => hide(context),
        ),
      ),
    );
  }

  // Function to manually close the snackbar
  static void hide(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}