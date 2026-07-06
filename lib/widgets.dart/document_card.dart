import 'package:flutter/material.dart';
import 'package:glapod/utils/app_colors.dart';
import 'package:glapod/utils/string_utilities.dart';
import 'package:lottie/lottie.dart'; // 🔹 1. Added Lottie import

class DocumentCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDownloading;
  final Future<bool> isDownloadedFuture;
  final VoidCallback onTap;

  const DocumentCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.isDownloading,
    required this.isDownloadedFuture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 5, right: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          StringUtils.toSentenceCase(title),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textHeadingBlack,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textSubtitle, fontSize: 13),
        ),
        trailing: isDownloading
            ? SizedBox(
                // 🔹 2. Expanded width/height to 42 for a perfect, prominent action size inside ListTile
                width: 42,
                height: 42,
                child: Lottie.asset(
                  'assets/animations/download_loader.json', // 🔹 Make sure this matches your JSON filename
                  fit: BoxFit
                      .contain, // Keeps composition ratios intact without distortion
                ),
              )
            : FutureBuilder<bool>(
                future: isDownloadedFuture,
                builder: (context, snapshot) {
                  final bool exists = snapshot.data ?? false;

                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: exists
                          ? Colors.green.withOpacity(0.1)
                          : AppColors.actionBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      exists
                          ? Icons.menu_book_rounded
                          : Icons.auto_stories_rounded,
                      size: 20,
                      color: exists ? Colors.green : AppColors.actionBlue,
                    ),
                  );
                },
              ),
        onTap: isDownloading ? null : onTap,
      ),
    );
  }
}
