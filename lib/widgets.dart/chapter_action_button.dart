import 'package:flutter/material.dart';
import 'package:glapod/utils/app_colors.dart';

class ChapterActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final dynamic chapterId;
  final Widget destination;
  final bool hasContent; // Updated parameter name

  const ChapterActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.chapterId,
    required this.destination,
    this.hasContent = true, // Default to true (Active)
  });

  @override
  Widget build(BuildContext context) {
    // Logic: If hasContent is false, we grey it out.
    final bool isGreyedOut = !hasContent;

    return GestureDetector(
      onTap: isGreyedOut
          ? () {
        // Optional: User feedback for disabled buttons
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("No $label available yet"),
            duration: const Duration(milliseconds: 800),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
          : () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // If it HAS content, show gradient. If NOT, no gradient.
              gradient: hasContent ? AppColors.actionGradient : null,

              // If it DOES NOT have content, show solid grey.
              color: hasContent ? null : Colors.grey.shade300,

              boxShadow: isGreyedOut
                  ? []
                  : [
                BoxShadow(
                  color: AppColors.actionBlueStart.withOpacity(0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 24,
              // Icon is white when active, medium grey when disabled
              color: hasContent ? Colors.white : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              // Text is black when active, light grey when disabled
              color: hasContent
                  ? AppColors.textHeadingBlack
                  : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}