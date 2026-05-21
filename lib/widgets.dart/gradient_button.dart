import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final String text;
  // CHANGE 1: Add '?' to make it nullable
  final VoidCallback? onPressed; 
  final double width;
  final double height;
  final LinearGradient gradient;
  final IconData? icon;
  final double borderRadius;
  final bool circularIcon;
  final MainAxisAlignment contentAlignment;
  final double iconSize;
  final double fontSize;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    required this.gradient,
    this.borderRadius = 30,
    this.icon,
    this.width = 300,
    this.height = 50,
    this.circularIcon = true,
    this.contentAlignment = MainAxisAlignment.center,
    this.iconSize = 22,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // CHANGE 3: GestureDetector handles null automatically (it will do nothing)
      onTap: onPressed, 
      child: Opacity(
        // OPTIONAL: Dim the button slightly if it's disabled
        opacity: onPressed == null ? 0.6 : 1.0,
        child: Container(
          width: width,
          height: height,
          // ... rest of your code stays exactly the same
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: gradient,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: contentAlignment,
            children: [
              if (icon != null) ...[
                circularIcon
                    ? Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                    child: Icon(icon, size: iconSize - 4, color: Color(0xFF2FB7FF)),
                      )
                    : Icon(icon, size: iconSize, color: Colors.white),
                const SizedBox(width: 10),
              ],

              Text(
                text,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                  ),
              ),
            ],
          ),
        ),
      ),
    )
    );
  }
}
