import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'widgets.dart/appbar_page.dart';
import 'video_listing.dart';
import 'notes_listing.dart';
import 'chapter_solutions_page.dart';
import 'widgets.dart/empty_state_widget.dart';

class SubjectDetailPage extends StatelessWidget {
  final String subjectName;
  final String subjectId;
  final List<dynamic> chapters;

  // Modern, energetic yet soft child-friendly theme colors
  final List<Color> themeColors = const [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF10B981), // Emerald Green
    Color(0xFFF43F5E), // Rose Pink
    Color(0xFF8B5CF6), // Purple
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF59E0B), // Amber Orange
  ];

  const SubjectDetailPage({
    super.key,
    required this.subjectName,
    required this.subjectId,
    required this.chapters,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6), // Smooth off-white surface
      appBar: CustomAppBar(height: 50, title: subjectName),
      body: chapters.isEmpty
          ? const EmptyStateWidget(msg: "No chapters available!")
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              itemCount: chapters.length,
              itemBuilder: (context, index) {
                final selectedColor = themeColors[index % themeColors.length];

                return ChapterAccordionItem(
                  chapter: chapters[index],
                  subjectId: subjectId,
                  subjectName: subjectName,
                  activeColor: selectedColor,
                );
              },
            ),
    );
  }
}

class ChapterAccordionItem extends StatefulWidget {
  final dynamic chapter;
  final String subjectId;
  final String subjectName;
  final Color activeColor;

  const ChapterAccordionItem({
    super.key,
    required this.chapter,
    required this.subjectId,
    required this.subjectName,
    required this.activeColor,
  });

  @override
  State<ChapterAccordionItem> createState() => _ChapterAccordionItemState();
}

class _ChapterAccordionItemState extends State<ChapterAccordionItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    // 1. Read real flags directly from your API response schema
    final bool showNotes = widget.chapter['notes'] == true;
    final bool showSolutions = widget.chapter['solutions'] == true;
    final bool showVideos = widget.chapter['videos'] == true;

    // Optional upcoming database flags (Change to match your API keys later if needed)
    final bool showPractice = widget.chapter['practice'] == true;
    final bool showQuiz = widget.chapter['quiz'] == true;

    // Check if there is absolutely nothing available inside this horizontal row
    final bool isRowEntirelyEmpty =
        !showNotes && !showSolutions && !showPractice && !showQuiz;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _isExpanded
              ? widget.activeColor.withOpacity(0.35)
              : widget.activeColor.withOpacity(0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.activeColor.withOpacity(_isExpanded ? 0.08 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          trailing: AnimatedRotation(
            turns: _isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 250),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: _isExpanded
                  ? widget.activeColor
                  : Colors.grey.shade100,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _isExpanded ? Colors.white : Colors.grey.shade600,
                size: 22,
              ),
            ),
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: widget.activeColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_stories_rounded,
              color: widget.activeColor,
              size: 22,
            ),
          ),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Text(
            (widget.chapter['title'] ?? "Untitled Chapter").toString(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937),
              letterSpacing: .1,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1, color: Color(0xFFF3F4F6)),
                  ),
                  const SizedBox(height: 16),

                  // Top Graphic Row (Image + Learning Progress Tracking)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child:
                              widget.chapter['image'] != null &&
                                  widget.chapter['image'].toString().isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: widget.chapter['image'],
                                  fit: BoxFit.cover,
                                  height: 85,
                                  width: 85,
                                  placeholder: (context, url) => Container(
                                    height: 85,
                                    width: 85,
                                    color: Colors.grey.shade100,
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: widget.activeColor,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        height: 85,
                                        width: 85,
                                        color: Colors.grey.shade100,
                                        child: Icon(
                                          Icons.image_not_supported_rounded,
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                )
                              : Container(
                                  height: 85,
                                  width: 85,
                                  color: widget.activeColor.withOpacity(0.05),
                                  child: Icon(
                                    Icons.image,
                                    color: widget.activeColor,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Chapter Progress",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: LinearProgressIndicator(
                                        value: 0.65,
                                        minHeight: 10,
                                        backgroundColor: widget.activeColor
                                            .withOpacity(0.12),
                                        valueColor: AlwaysStoppedAnimation(
                                          widget.activeColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "65%",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: widget.activeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🌟 HORIZONTALLY SCROLLABLE OPTIONS ROW 🌟
                  if (isRowEntirelyEmpty)
                    // Playful placeholder shown ONLY if everything else is hidden
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Text("🚀", style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 12),
                            Text(
                              "New learning adventures coming soon!",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          // Conditionals completely remove widgets if flag is false
                          if (showNotes)
                            _buildActionCard(
                              context,
                              icon: Icons.edit_note_rounded,
                              label: "Read Notes",
                              description: "Quick summary",
                              accentColor: const Color(0xFF3B82F6),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NotesListingPage(
                                    chapterId: widget.chapter['id'].toString(),
                                    chapterTitle: widget.chapter['title']
                                        .toString(),
                                  ),
                                ),
                              ),
                            ),
                          if (showSolutions)
                            _buildActionCard(
                              context,
                              icon: Icons.menu_book_rounded,
                              label: "Solutions",
                              description: "Step-by-step",
                              accentColor: const Color(0xFF10B981),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChapterSolutionsPage(
                                    subjectId: widget.subjectId,
                                    chapterId: widget.chapter['id'].toString(),
                                    chapterTitle: widget.chapter['title'],
                                  ),
                                ),
                              ),
                            ),
                          if (showPractice)
                            _buildActionCard(
                              context,
                              icon: Icons.assignment_rounded,
                              label: "Practice",
                              description: "Test skill mock",
                              accentColor: const Color(0xFFFF9800),
                              onTap: () {},
                            ),
                          if (showQuiz)
                            _buildActionCard(
                              context,
                              icon: Icons.emoji_events_rounded,
                              label: "Daily Quiz",
                              description: "Earn trophies",
                              accentColor: const Color(0xFFEC4899),
                              onTap: () {},
                            ),
                        ],
                      ),
                    ),

                  // Only display video section or separation logic if video module is true
                  if (showVideos) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _buildVideoRowAction(
                        context,
                        accentColor: widget.activeColor,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoListingPage(
                              chapterTitle: widget.chapter['title'] ?? "Videos",
                              chapterId: widget.chapter['id'].toString(),
                              subjectName: widget.subjectName,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Horizontal Scroll Resource Item Card Component
  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 165,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentColor.withOpacity(0.15), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modernized Video Player CTA Block layout
  Widget _buildVideoRowAction(
    BuildContext context, {
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [accentColor, accentColor.withOpacity(0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.play_arrow_rounded,
                color: Color(0xFF1F2937),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            const Text(
              "Watch Video Lessons",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Colors.white,
                letterSpacing: .2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
