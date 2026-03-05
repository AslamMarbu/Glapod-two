import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:glapod/chapter_listing.dart'; // Make sure to import your new detail page
import 'package:glapod/question_papers_page.dart';
import 'package:glapod/solutions_page.dart'; // Import the solutions page

class SubjectCard extends StatelessWidget {
  final String title;
  final String? syllabusUrl;
  final String? textbookUrl;
  final List<dynamic> chapters;

  const SubjectCard({
    super.key,
    required this.title,
    this.syllabusUrl,
    this.textbookUrl,
    required this.chapters,
  });

  // Function to handle the "Download/Open" logic for PDF/Links
  Future<void> _downloadFile(BuildContext context, String? url, String type) async {
    if (url == null || url.isEmpty || url == "null") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No $type available")),
      );
      return;
    }

    final String cleanUrl = url.trim();
    final Uri uri = Uri.parse(cleanUrl);

    try {
      bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) throw 'Launch returned false';
    } catch (e) {
      debugPrint("Error launching URL: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open. Make sure a browser is installed.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- CLICKABLE SUBJECT TITLE ---
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubjectDetailPage(
                    subjectName: title,
                    chapters: chapters,
                  ),
                ),
              );
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$title >",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildIconColumn(
                context,
                Icons.book,
                "Textbook",
                onTap: () => _downloadFile(context, textbookUrl, "textbook"),
              ),
              _buildIconColumn(
                context,
                Icons.description,
                "Syllabus",
                onTap: () => _downloadFile(context, syllabusUrl, "syllabus"),
              ),
              _buildIconColumn(
                context,
                Icons.help,
                "Questions",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuestionPapersPage(
                        subjectName: title, // optional if you want to pass subject
                      ),
                    ),
                  );
                },
              ),
              _buildIconColumn(
                context,
                Icons.lightbulb,
                "Solutions",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SolutionsPage(
                        subjectName: title,
                        chapters: chapters,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconColumn(
      BuildContext context,
      IconData icon,
      String label, {
        VoidCallback? onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blue.withOpacity(0.1),
            child: Icon(icon, size: 20, color: Colors.blue),
          ),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}