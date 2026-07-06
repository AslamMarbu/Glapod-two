import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:glapod/questions_page.dart';
import 'package:glapod/chapter_listing.dart';
import 'package:glapod/question_bank.dart';
import 'package:glapod/textbook_listing_page.dart';
import 'package:glapod/sample_papers_page.dart';

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

  final bool isInitiallyExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final VoidCallback onNavigateToChapters;
  final Color primaryColor;

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
    this.isInitiallyExpanded = false,
    required this.onExpansionChanged,
    required this.onNavigateToChapters,
    required this.primaryColor,
  });

  @override
  State<SubjectCard> createState() => _SubjectCardState();
}

class _SubjectCardState extends State<SubjectCard> {
  bool get _isExpanded => widget.isInitiallyExpanded;

  void _handleNavigation(BuildContext context) {
    if (widget.chapters == null || widget.chapters!.isEmpty) {
      _showNoChaptersSnackBar(context);
    } else {
      widget.onNavigateToChapters();

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
    int chapterCount = widget.chapters?.length ?? 0;

    final Color lightBgTint = widget.primaryColor.withOpacity(0.08);
    final Color borderTint = widget.primaryColor.withOpacity(0.25);

    // 1. Define our resource items list with their natural initial order positions
    final List<Map<String, dynamic>> resourceItems = [
      {
        'title': 'Textbook',
        'subtitle': 'Read books',
        'icon': Icons.menu_book_rounded,
        'color': lightBgTint,
        'iconColor': widget.primaryColor,
        'isEnabled': widget.textbooksList.isNotEmpty,
        'page': widget.textbooksList.isNotEmpty
            ? TextbookListingPage(
                subjectName: widget.subjectName,
                textbooks: widget.textbooksList,
              )
            : null,
      },
      {
        'title': 'Syllabus',
        'subtitle': 'Course roadmap',
        'icon': Icons.assignment_outlined,
        'color': lightBgTint,
        'iconColor': widget.primaryColor,
        'isEnabled':
            widget.syllabusUrl != null &&
            widget.syllabusUrl!.isNotEmpty &&
            widget.syllabusUrl != "null",
        'url': widget.syllabusUrl,
      },
      {
        'title': 'Practice',
        'subtitle': 'Mock papers',
        'icon': Icons.quiz_outlined,
        'color': lightBgTint,
        'iconColor': widget.primaryColor,
        'isEnabled': widget.isSamplePaperEnabled,
        'page': widget.isSamplePaperEnabled
            ? SamplePapersPage(
                subjectId: widget.subjectId,
                subjectName: widget.subjectName,
                classId: widget.classId,
              )
            : null,
      },
      {
        'title': 'Questions',
        'subtitle': 'Chapter Q&A',
        'icon': Icons.help_outline_rounded,
        'color': lightBgTint,
        'iconColor': widget.primaryColor,
        'isEnabled': widget.isQuestionsEnabled,
        'page': widget.isQuestionsEnabled
            ? QuestionsPage(
                subjectId: widget.subjectId,
                subjectName: widget.subjectName,
              )
            : null,
      },
      {
        'title': 'Q Bank',
        'subtitle': 'Exam prep',
        'icon': Icons.layers_outlined,
        'color': lightBgTint,
        'iconColor': widget.primaryColor,
        'isEnabled': widget.isQuestionBankEnabled,
        'page': widget.isQuestionBankEnabled
            ? QuestionBankPage(
                subjectId: widget.subjectId,
                subjectName: widget.subjectName,
                classId: widget.classId,
              )
            : null,
      },
    ];

    // 2. SORTING LOGIC: Moves active content items to the front.
    // Stable sort preserves default sequence order if both match or all items are active!
    resourceItems.sort((a, b) {
      final bool aEnabled = a['isEnabled'] ?? false;
      final bool bEnabled = b['isEnabled'] ?? false;

      if (aEnabled && !bEnabled) return -1; // 'a' moves up
      if (!aEnabled && bEnabled) return 1; // 'b' moves up
      return 0; // maintain default sorting order
    });

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderTint, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: lightBgTint,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: widget.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subjectName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "$chapterCount Chapters",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => widget.onExpansionChanged(!_isExpanded),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_isExpanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                color: widget.primaryColor.withOpacity(0.1),
                height: 1,
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 0, 16),
              child: SizedBox(
                height: 120,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.imageUrl != null &&
                        widget.imageUrl!.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrl!,
                          width: 90,
                          height: 120,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 90,
                            height: 120,
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 90,
                            height: 120,
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.book_rounded,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: resourceItems.length,
                        itemBuilder: (context, index) {
                          final item = resourceItems[index];
                          final bool isItemEnabled = item['isEnabled'] ?? false;

                          return GestureDetector(
                            onTap: isItemEnabled
                                ? () {
                                    if (item['page'] != null) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => item['page'],
                                        ),
                                      );
                                    }
                                  }
                                : null,
                            child: Opacity(
                              opacity: isItemEnabled ? 1.0 : 0.45,
                              child: Container(
                                width: 160,
                                margin: const EdgeInsets.only(
                                  right: 14,
                                  bottom: 4,
                                  top: 4,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: isItemEnabled
                                        ? borderTint
                                        : Colors.grey.withOpacity(0.2),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.primaryColor.withOpacity(
                                        0.01,
                                      ),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: isItemEnabled
                                            ? item['color']
                                            : Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(
                                        item['icon'],
                                        color: isItemEnabled
                                            ? item['iconColor']
                                            : Colors.grey.shade400,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['title'],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: isItemEnabled
                                                  ? const Color(0xFF1E293B)
                                                  : Colors.grey.shade600,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item['subtitle'],
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _handleNavigation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.arrow_circle_right_rounded, size: 24),
                      SizedBox(width: 12),
                      Text(
                        "View All Chapters",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
