import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/study_provider.dart';
import 'widgets.dart/appbar_page.dart';
import 'widgets.dart/subject_card.dart';
import 'widgets.dart/app_refresh_wrapper.dart';
import 'storage/local_storage_service.dart';

class Study extends StatefulWidget {
  const Study({super.key});

  @override
  State<Study> createState() => _StudyState();
}

class _StudyState extends State<Study> {
  // Keeps track of which subject card is currently expanded (-1 means none)
  int _expandedIndex = -1;

  String _className = "";

  final Map<String, Color> _subjectColors = {
    "Physics": const Color(0xFF2962FF), // Royal Blue
    "Chemistry": const Color(0xFFE91E63), // Emerald Green
    "Biology": const Color(0xFF43A047), // Leaf Green
    "Mathematics": const Color(0xFF00BCD4), // Cyan
    "History": const Color(0xFF7B1FA2), // Deep Purple
    "Geography": const Color(0xFFF06801), // Brand Orange
    "Economics": const Color(0xFF00C853), // Pink
    "Political Science": const Color(0xFF3F51B5), // Indigo
    "Political Science/Civics": const Color(0xFF3F51B5),
    "Civics": const Color(0xFF3F51B5),
    "English": const Color(0xFFD32F2F), // Crimson Red
    "Hindi": const Color(0xFFFFB300), // Amber
    "Sanskrit": const Color(0xFF8E244D), // Maroon
  };

  final Map<String, int> _subjectOrder = {
    "Physics": 1,
    "Chemistry": 2,
    "Biology": 3,
    "Mathematics": 4,
    "History": 5,
    "Geography": 6,
    "Economics": 7,
    "Political Science": 8,
    "Civics": 8,
    "Political Science/Civics": 8,
    "English": 9,
    "Hindi": 10,
    "Sanskrit": 11,
  };

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load student class name
      final student = await LocalStorageService.getStudent();

      if (mounted && student != null) {
        setState(() {
          _className = (student['class_name'] ?? '').toString();
        });
      }

      // Load subjects
      await context.read<StudyProvider>().loadSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    final studyProvider = context.watch<StudyProvider>();
    final subjects = List<Map<String, dynamic>>.from(studyProvider.subjects);

    subjects.sort((a, b) {
      final nameA = (a["subject"] ?? "").toString().trim();
      final nameB = (b["subject"] ?? "").toString().trim();

      final orderA = _subjectOrder[nameA] ?? 999;
      final orderB = _subjectOrder[nameB] ?? 999;

      if (orderA != orderB) {
        return orderA.compareTo(orderB);
      }

      return nameA.compareTo(nameB);
    });
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: CustomAppBar(
        height: 70,
        title: _className.isNotEmpty ? _className : "Class",
        isSubtitle: true,
        isDashboard: false,
      ),
      body: AppRefreshWrapper(
        onRefresh: () async {
          // Close any expanded subject card.a
          setState(() {
            _expandedIndex = -1;
          });

          // Fetch the subjects again from the API.
          await context.read<StudyProvider>().loadSubjects();
        },
        child: studyProvider.isLoading
            ? _buildShimmerLoading(screenHeight)
            : subjects.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 250),
                  Center(child: Text("No subjects available")),
                ],
              )
            : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: subjects.length,
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemBuilder: (context, index) {
                  final item = subjects[index];

                  final String subjectName = (item["subject"] ?? "").toString();

                  final Color assignedColor =
                      _subjectColors[subjectName] ?? const Color(0xFF2962FF);

                  final textbooks = item['textbooks_url'] is List
                      ? item['textbooks_url'] as List
                      : [];

                  return SubjectCard(
                    subjectId: item['id'].toString(),
                    subjectName: subjectName,
                    imageUrl: item['image_url'],
                    syllabusUrl: item['syllabus_url'],
                    textbooksList: textbooks,
                    textbookUrl: textbooks.isNotEmpty
                        ? textbooks.first['file']
                        : null,
                    chapters: item['chapters'] ?? [],
                    classId: studyProvider.savedClassId,
                    primaryColor: assignedColor,
                    isQuestionBankEnabled:
                        item['question_bank'] == true ||
                        item['question_bank'] == 1,
                    isQuestionsEnabled:
                        item['question'] == true || item['question'] == 1,
                    isSamplePaperEnabled:
                        item['sample_paper'] == true ||
                        item['sample_paper'] == 1,
                    isInitiallyExpanded: _expandedIndex == index,
                    onExpansionChanged: (isExpanded) {
                      setState(() {
                        _expandedIndex = isExpanded ? index : -1;
                      });
                    },
                    onNavigateToChapters: () {
                      setState(() {
                        _expandedIndex = -1;
                      });
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildShimmerLoading(double screenHeight) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
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
