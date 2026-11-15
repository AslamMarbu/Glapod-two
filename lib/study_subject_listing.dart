import 'dart:math';
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

  final Map<String, GlobalKey> _subjectKeys = {};
  final List<Color> _colorPalette = [
    const Color(0xFF4F46E5),
    const Color(0xFF10B981),
    const Color(0xFFF43F5E),
    const Color(0xFF8B5CF6),
    const Color(0xFF06B6D4),
    const Color(0xFFF59E0B),
    const Color(0xFF3B82F6),
    const Color(0xFFEC4899),
    const Color(0xFF14B8A6),
    const Color(0xFFEF4444),
    const Color(0xFF84CC16),
    const Color(0xFFA855F7),
    const Color(0xFFF97316),
    const Color(0xFF0EA5E9),
    const Color(0xFF22C55E),
    const Color(0xFFD946EF),
    const Color(0xFF6366F1),
    const Color(0xFF0891B2),
    const Color(0xFFCA8A04),
    const Color(0xFFDB2777),
    const Color(0xFF059669),
    const Color(0xFF7C3AED),
    const Color(0xFFEA580C),
    const Color(0xFF2563EB),
    const Color(0xFF65A30D),
  ];

  final Map<String, Color> _subjectColors = {};

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
      final student = await LocalStorageService.getStudent();

      if (mounted && student != null) {
        setState(() {
          _className = (student['class_name'] ?? '').toString();
        });
      }

      await context.read<StudyProvider>().loadSubjects();

      if (mounted) {
        setState(() {
          _subjectColors.clear();
          _assignSubjectColors(
            List<Map<String, dynamic>>.from(
              context.read<StudyProvider>().subjects,
            ),
          );
        });
      }
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
          setState(() {
            _expandedIndex = -1;
          });

          await context.read<StudyProvider>().loadSubjects();

          if (mounted) {
            setState(() {
              _subjectColors.clear();
              _assignSubjectColors(
                List<Map<String, dynamic>>.from(
                  context.read<StudyProvider>().subjects,
                ),
              );
            });
          }
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
                    key: _subjectKeys.putIfAbsent(
                      item['id'].toString(),
                      () => GlobalKey(),
                    ),
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

                      if (isExpanded) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final cardContext =
                              _subjectKeys[item['id'].toString()]
                                  ?.currentContext;

                          if (cardContext != null) {
                            Scrollable.ensureVisible(
                              cardContext,
                              alignment: 0.5,
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.easeInOut,
                            );
                          }
                        });
                      }
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

  void _assignSubjectColors(List<Map<String, dynamic>> subjects) {
    final colors = List<Color>.from(_colorPalette);
    colors.shuffle(Random());

    for (int i = 0; i < subjects.length; i++) {
      final name = (subjects[i]['subject'] ?? '').toString().trim();

      if (name.isNotEmpty && !_subjectColors.containsKey(name)) {
        _subjectColors[name] = colors[i % colors.length];
      }
    }
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
