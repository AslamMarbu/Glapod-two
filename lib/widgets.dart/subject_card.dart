import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🔹 Essential for caching
import 'package:glapod/questions_page.dart';
import 'package:glapod/chapter_listing.dart';
import 'package:glapod/question_bank.dart';
import 'package:glapod/textbook_listing_page.dart';
import 'package:glapod/sample_papers_page.dart';
import 'subject_circular_icon.dart';

class SubjectCard extends StatefulWidget {
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
  final bool isSamplePaperEnabled;

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
    this.isSamplePaperEnabled = true,
  });

  @override
  State<SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<SubjectCard> {
  bool _isExpanded = false;

  void _handleNavigation(BuildContext context) {
    if (widget.chapters == null || widget.chapters!.isEmpty) {
      _showNoChaptersSnackBar(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubjectDetailPage(
            subjectId: widget.subjectId,
            subjectName: widget.subjectName,
            chapters: widget.chapters!,
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
        children: [
          // 1. HEADER BANNER (With Image Caching)
          InkWell(
            onTap: () => _handleNavigation(context),
            borderRadius: BorderRadius.circular(25),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                image: (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                    ? DecorationImage(
                  // 🔹 Using Provider here to work inside BoxDecoration
                  image: CachedNetworkImageProvider(widget.imageUrl!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.3),
                    BlendMode.darken,
                  ),
                )
                    : null,
                color: Colors.grey.shade200,
              ),
              alignment: Alignment.center,
              child: Text(
                widget.subjectName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                        blurRadius: 8,
                        color: Colors.black54,
                        offset: Offset(2, 2)
                    )
                  ],
                ),
              ),
            ),
          ),

          // 2. ACCORDION TRIGGER BAR
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.grey,
                  size: 28,
                ),
              ),
            ),
          ),

          // 3. EXPANDABLE CONTENT
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 15, 20),
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 15,
                children: [
                  CircularIconButton(
                    icon: Icons.menu_book_rounded,
                    label: "Textbook",
                    backgroundColor: const Color(0xFF4DB6AC),
                    isEnabled: widget.textbooksList.isNotEmpty,
                    page: widget.textbooksList.isNotEmpty
                        ? TextbookListingPage(
                      subjectName: widget.subjectName,
                      textbooks: widget.textbooksList,
                    )
                        : null,
                  ),
                  CircularIconButton(
                    icon: Icons.assignment_outlined,
                    label: "Syllabus",
                    backgroundColor: const Color(0xFF9575CD),
                    isEnabled: widget.syllabusUrl != null &&
                        widget.syllabusUrl!.isNotEmpty &&
                        widget.syllabusUrl != "null",
                    url: widget.syllabusUrl,
                  ),
                  CircularIconButton(
                    icon: Icons.quiz_outlined,
                    label: "Practice",
                    backgroundColor: const Color(0xFFFF8A65),
                    isEnabled: widget.isSamplePaperEnabled,
                    page: widget.isSamplePaperEnabled
                        ? SamplePapersPage(
                      subjectId: widget.subjectId,
                      subjectName: widget.subjectName,
                      classId: widget.classId,
                    )
                        : null,
                  ),
                  CircularIconButton(
                    icon: Icons.help_outline_rounded,
                    label: "Questions",
                    backgroundColor: const Color(0xFF64B5F6),
                    isEnabled: widget.isQuestionsEnabled,
                    page: widget.isQuestionsEnabled
                        ? QuestionsPage(
                      subjectId: widget.subjectId,
                      subjectName: widget.subjectName,
                    )
                        : null,
                  ),
                  CircularIconButton(
                    icon: Icons.quiz_outlined,
                    label: "Q Bank",
                    backgroundColor: const Color(0xFFA29BFE),
                    isEnabled: widget.isQuestionBankEnabled,
                    page: widget.isQuestionBankEnabled
                        ? QuestionBankPage(
                      subjectId: widget.subjectId,
                      subjectName: widget.subjectName,
                      classId: widget.classId,
                    )
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}