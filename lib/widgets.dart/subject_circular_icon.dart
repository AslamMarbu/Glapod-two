import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:glapod/pdf_view_page.dart';
import 'package:glapod/utils/app_colors.dart';

class CircularIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? url;
  final Widget? page;
  final bool isEnabled;
  final bool isLoading;
  final Color backgroundColor;
  final VoidCallback? onTap;

  const CircularIconButton({
    super.key,
    required this.icon,
    required this.label,
    this.url,
    this.page,
    this.isEnabled = true,
    this.isLoading = false,
    this.backgroundColor = const Color(0xFF4DB6AC),
    this.onTap,
  });

  bool _isUrlValid(String? input) {
    if (input == null || input.isEmpty) return false;
    final cleanUrl = input.trim().toLowerCase();
    return cleanUrl != "null" && cleanUrl.startsWith('http');
  }

  void _handleTap(BuildContext context) {
    if (!isEnabled || isLoading) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (onTap != null) {
      onTap!();
      return;
    }

    if (page != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
      return;
    }

    if (_isUrlValid(url)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerPage(url: url!.trim(), title: label),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text("No $label available"),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Responsive scaling (safe)
    final width = MediaQuery.of(context).size.width;
    final iconSize = width < 400 ? 22.0 : 24.0; // ~24 on phones
    final paddingSize = width * 0.025; // ~10
    final textSize = width < 400 ? 11.5 : 12.5; // ~10

    if (isLoading) {
      return _buildShimmerPlaceholder(width);
    }

    return InkWell(
      onTap: isEnabled ? () => _handleTap(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: width * 0.02,
          horizontal: width * 0.01,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(paddingSize),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isEnabled ? backgroundColor : Colors.grey.shade300,
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: backgroundColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isEnabled ? Colors.white : Colors.grey.shade100,
                size: iconSize,
              ),
            ),
            SizedBox(height: width * 0.02),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2, // 🔹 Prevent overflow
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: textSize,
                fontWeight: FontWeight.w600,
                color: isEnabled ? AppColors.textHeadingBlack : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Improved shimmer (responsive)
  Widget _buildShimmerPlaceholder(double width) {
    final size = width * 0.11; // circle size

    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: width * 0.02,
          horizontal: width * 0.01,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            SizedBox(height: width * 0.02),
            Container(
              width: width * 0.1,
              height: width * 0.025,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
