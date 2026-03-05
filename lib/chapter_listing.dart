import 'package:flutter/material.dart';
import 'widgets.dart/appbar_page.dart';
import 'video_listing.dart';
import 'notes_listing.dart';
import 'widgets.dart/chapter_action_button.dart'; // Add this import


class SubjectDetailPage extends StatelessWidget {
  final String subjectName;
  final List<dynamic> chapters;

  const SubjectDetailPage({
    super.key,
    required this.subjectName,
    required this.chapters, // These are passed from the previous screen
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(height: 100),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              subjectName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: chapters.isEmpty
                ? const Center(child: Text("No chapters available"))
                : ListView.builder(
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final chapter = chapters[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    title: Text(
                      chapter['title'] ?? "Untitled Chapter",
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ChapterActionButton(
                              icon: Icons.assignment,
                              label: "Notes",
                              chapterId: chapter['id'],
                              destination: NotesListingPage(),
                            ),
                            ChapterActionButton(
                              icon: Icons.play_circle_fill,
                              label: "Video",
                              chapterId: chapter['id'],
                              destination: VideoListingPage(chapterTitle: chapter['title'] ?? "Videos", chapterId:chapter['id']),
                            ),
                            ChapterActionButton(
                              icon: Icons.quiz,
                              label: "Quiz",
                              chapterId: chapter['id'],
                              destination: const Scaffold(body: Center(child: Text("Quiz Page"))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

}