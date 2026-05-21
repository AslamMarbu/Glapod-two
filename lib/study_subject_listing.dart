import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/study_provider.dart';
import 'widgets.dart/appbar_page.dart';
import 'widgets.dart/subject_card.dart';

class Study extends StatefulWidget {
  const Study({super.key});

  @override
  State<Study> createState() => _StudyState();
}

class _StudyState extends State<Study> {
  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback to trigger the logic after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudyProvider>().loadSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final studyProvider = context.watch<StudyProvider>();
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: const CustomAppBar(
        height: 40,
        title: "Study",
        isDashboard: false,
      ),
      body: studyProvider.isLoading
          ? _buildShimmerLoading(screenHeight)
          : studyProvider.subjects.isEmpty
          ? const Center(child: Text("No subjects available"))
          : ListView.builder(
        itemCount: studyProvider.subjects.length,
        padding: const EdgeInsets.symmetric(vertical: 20),
        itemBuilder: (context, index) {
          final item = studyProvider.subjects[index];
          return SubjectCard(
            subjectId: item['id'].toString(),
            subjectName: item["subject"],
            imageUrl: item['image_url'],
            syllabusUrl: item['syllabus_url'],
            textbooksList: item['textbooks_url'] ?? [],
            textbookUrl: (item['textbooks_url'] != null &&
                item['textbooks_url'].isNotEmpty)
                ? item['textbooks_url'][0]['file']
                : null,
            chapters: item['chapters'] ?? [],
            classId: studyProvider.savedClassId,
            isQuestionBankEnabled: item['question_bank'] == true || item['question_bank'] == 1,
            isQuestionsEnabled: item['question'] == true || item['question'] == 1,
            isSamplePaperEnabled: item['sample_paper'] == true || item['sample_paper'] == 1,
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoading(double screenHeight) {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            height: screenHeight * 0.22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      },
    );
  }
}