import 'package:flutter/material.dart';
import 'widgets.dart/chapter_dropdowns.dart';
import 'widgets.dart/appbar_page.dart';

class SyllabusPage extends StatelessWidget {
  final String subjectName;
  final List<dynamic> chapters;

  const SyllabusPage({
    super.key,
    required this.subjectName,
    required this.chapters
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("$subjectName Syllabus")),
      body: chapters.isEmpty
          ? const Center(child: Text("No chapters available"))
          : ListView.builder(
        itemCount: chapters.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(child: Text("${index + 1}")),
            title: Text(chapters[index]['title'] ?? "No Title"),
          );
        },
      ),
    );
  }
}