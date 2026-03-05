import 'package:flutter/material.dart';

class SolutionsPage extends StatelessWidget {
  final String subjectName;
  final List<dynamic> chapters;

  const SolutionsPage({
    super.key,
    required this.subjectName,
    required this.chapters,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text('Textbook Solutions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$subjectName Solutions',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: 1, // As we are dealing with the subject, not individual chapters
                itemBuilder: (context, index) {
                  return _buildSubjectCard(context, subjectName, chapters.length);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, String title, int chapterCount) {
    return GestureDetector(
      onTap: () {
        // Handle the action when tapping on a subject card
        // For now, we could display another page or show the chapters
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Icon next to the subject name
            CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.library_books, color: Colors.white),
            ),
            const SizedBox(width: 16),
            // Title and Chapter Count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$chapterCount chapters',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow icon for navigation (optional)
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}