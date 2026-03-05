import 'package:flutter/material.dart';
import 'widgets.dart/appbar_page.dart';
import 'widgets.dart/subject_card.dart';
import 'services/student_service.dart';
import 'storage/local_storage_service.dart';
import 'utils/logger.dart';
class Study extends StatefulWidget {
  const Study({super.key});

  @override
  State<Study> createState() => _StudyState();
}

class _StudyState extends State<Study> {
  List<dynamic> subjects = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    // Log the start of the process
    //AppLogger.log("Starting to load subjects...", tag: "STUDY_PAGE");

    final studentData = await LocalStorageService.getStudent();
    final classId = studentData?['class_id']?.toString() ?? "3";

    //AppLogger.log("Using classId: $classId", tag: "STUDY_PAGE");

    final fetchedSubjects = await StudentService.fetchSubjects(classId);

    // Log the raw list or length to verify multiple items are present
    //AppLogger.log("Fetched ${fetchedSubjects.length} subjects", tag: "STUDY_PAGE");
    //AppLogger.log("Subjects Data: $fetchedSubjects", tag: "STUDY_PAGE");

    if (mounted) {
      setState(() {
        subjects = fetchedSubjects;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(height: 100),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : subjects.isEmpty
          ? const Center(child: Text("No subjects available"))
          : ListView.builder(
        // ✅ CRITICAL: This must be the length of your API list
        itemCount: subjects.length,
        padding: const EdgeInsets.symmetric(vertical: 20),
        itemBuilder: (context, index) {
          final item = subjects[index];
          return SubjectCard(
            title: item['subject'] ?? "Unknown",
            syllabusUrl: item['syllabus_url'],
            textbookUrl: item['textbook_url'],
            chapters: item['chapters'] ?? [],
          );
        },
      ),
    );
  }
}