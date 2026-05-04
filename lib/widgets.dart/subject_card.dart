import 'package:flutter/material.dart';
import 'package:glapod/questions_page.dart';
import 'package:glapod/utils/app_colors.dart';
import 'subject_circular_icon.dart';
import 'package:glapod/chapter_listing.dart';
import 'package:glapod/question_bank.dart';
import 'package:glapod/textbook_listing_page.dart';
import 'package:glapod/sample_papers_page.dart';

class SubjectCard extends StatelessWidget {
  final String subjectId;
  final String? syllabusUrl;
  final String? textbookUrl;
  final List<dynamic> textbooksList;
  final String subjectName;
  final String classId;
  final List<dynamic>? chapters;
  final String? imageUrl;

  final bool isQuestionBankEnabled;
  final bool isQuestionsEnabled;

  const SubjectCard({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.textbooksList,
    this.syllabusUrl,
    this.textbookUrl,
    this.chapters,
    required this.classId,
    this.imageUrl,
    this.isQuestionBankEnabled = true,
    this.isQuestionsEnabled = true,
  });

  void _handleNavigation(BuildContext context) {
    if (chapters == null || chapters!.isEmpty) {
      _showNoChaptersSnackBar(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubjectDetailPage(
            subjectId: subjectId,
            subjectName: subjectName,
            chapters: chapters!,
          ),
        ),
      );
    }
  }

  void _showNoChaptersSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("No chapters available"),
        backgroundColor: Colors.black87,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 Responsive values (safe scaling)
    final width = MediaQuery.of(context).size.width;
    final imageWidth = width * 0.25;   // ~100 on normal phones
    final imageHeight = width * 0.38;  // keeps same ratio feel

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- HEADER ---
          InkWell(
            onTap: () => _handleNavigation(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 5),
              child: Row(
                children: [
                  // 🔹 Prevent overflow for long names
                  Expanded(
                    child: Text(
                      subjectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHeadingBlack,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ),

          const Divider(
            thickness: 1.0,
            indent: 20,
            endIndent: 20,
            color: Color(0xFFF5F5F5),
          ),

          // --- CONTENT ---
          Padding(
            padding: const EdgeInsets.only(bottom: 15, top: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Image
                InkWell(
                  onTap: () => _handleNavigation(context),
                  borderRadius: BorderRadius.circular(15),
                  child: Container(
                    width: imageWidth,
                    height: imageHeight,
                    margin: const EdgeInsets.only(left: 20, right: 5),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(15),
                      image: (imageUrl != null && imageUrl!.isNotEmpty)
                          ? DecorationImage(
                        image: NetworkImage(imageUrl!),
                        fit: BoxFit.cover,
                      )
                          : null,
                    ),
                    child: (imageUrl == null || imageUrl!.isEmpty)
                        ? Icon(
                      Icons.image,
                      color: Colors.grey.shade300,
                      size: 30,
                    )
                        : null,
                  ),
                ),

                // 🔹 Grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.75,
                    children: [
                      CircularIconButton(
                        icon: Icons.menu_book_rounded,
                        label: "Textbook",
                        backgroundColor: const Color(0xFF4DB6AC),
                        isEnabled: textbooksList.isNotEmpty,
                        page: textbooksList.isNotEmpty
                            ? TextbookListingPage(
                          subjectName: subjectName,
                          textbooks: textbooksList,
                        )
                            : null,
                      ),
                      CircularIconButton(
                        icon: Icons.assignment_outlined,
                        label: "Syllabus",
                        backgroundColor: const Color(0xFF9575CD),
                        isEnabled: syllabusUrl != null &&
                            syllabusUrl!.isNotEmpty &&
                            syllabusUrl != "null",
                        url: syllabusUrl,
                      ),
                      CircularIconButton(
                        icon: Icons.quiz_outlined,
                        label: "Practice",
                        backgroundColor: const Color(0xFFFF8A65),
                        isEnabled: isQuestionBankEnabled,
                        page: isQuestionBankEnabled
                            ? SamplePapersPage(
                          subjectId: subjectId,
                          subjectName: subjectName,
                          classId: classId,
                        )
                            : null,
                      ),
                      CircularIconButton(
                        icon: Icons.help_outline_rounded,
                        label: "Questions",
                        backgroundColor: const Color(0xFF64B5F6),
                        isEnabled: isQuestionsEnabled,
                        page: isQuestionsEnabled
                            ? QuestionsPage(
                          subjectId: subjectId,
                          subjectName: subjectName,
                        )
                            : null,
                      ),
                      CircularIconButton(
                        icon: Icons.quiz_outlined,
                        label: "Q Bank",
                        backgroundColor: const Color(0xFFA29BFE),
                        isEnabled: isQuestionBankEnabled,
                        page: isQuestionBankEnabled
                            ? QuestionBankPage(
                          subjectId: subjectId,
                          subjectName: subjectName,
                          classId: classId,
                        )
                            : null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}