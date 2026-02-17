import 'package:flutter/material.dart';
import 'widgets.dart/appbar_page.dart';
import 'widgets.dart/subject_card.dart';

class Study extends StatelessWidget {
  const Study({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(height: 100),

      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        children: const [
          SubjectCard(title: "Subject 1 >"),
          SubjectCard(title: "Subject 2 >"),
          SubjectCard(title: "Subject 3 >"),
          SubjectCard(title: "Subject 4 >"),
          SubjectCard(title: "Subject 5 >"),
          SubjectCard(title: "Subject n >"),
        ],
      ),
    );
  }
}
