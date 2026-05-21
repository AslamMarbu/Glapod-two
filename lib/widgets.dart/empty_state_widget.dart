import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final String msg;

  const EmptyStateWidget({
    super.key,
    required this.msg,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Classic Icon with a soft circular background
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF1B75BB).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.folder_open_rounded, // Classic "no data" icon
                size: 80,
                color: Color(0xFF1B75BB),
              ),
            ),
            const SizedBox(height: 24),

            // The Message Title
            const Text(
              "No Results Found",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 12),

            // The Dynamic Parameter Message
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}