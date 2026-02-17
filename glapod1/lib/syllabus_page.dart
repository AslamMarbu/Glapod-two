import 'package:flutter/material.dart';
import 'widgets.dart/chapter_dropdowns.dart';
import 'widgets.dart/appbar_page.dart';

class SyllabusPage extends StatelessWidget {
  const SyllabusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(height: 150),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: const ChapterDropdowns(),
      ),
    );
  }
}
