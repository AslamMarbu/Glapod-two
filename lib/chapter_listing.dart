import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🔹 Added for caching
import 'package:glapod/utils/app_colors.dart';
import 'widgets.dart/appbar_page.dart';
import 'video_listing.dart';
import 'notes_listing.dart';
import 'chapter_solutions_page.dart';
import 'widgets.dart/empty_state_widget.dart';

class SubjectDetailPage extends StatelessWidget {
  final String subjectName;
  final String subjectId;
  final List<dynamic> chapters;

  final List<Color> themeColors = const [
    Color(0xFF1A2B52),
    Color(0xFF2E7D32),
    Color(0xFFC62828),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
    Color(0xFFEF6C00),
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
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: CustomAppBar(height: 40, title: subjectName),
      body: chapters.isEmpty
          ? const EmptyStateWidget(msg: "No chapters available!")
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: chapters.length,
        itemBuilder: (context, index) {
          final selectedColor =
          themeColors[index % themeColors.length];

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
  State<ChapterAccordionItem> createState() =>
      _ChapterAccordionItemState();
}

class _ChapterAccordionItemState
    extends State<ChapterAccordionItem> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final imageHeight = width * 0.22;

    final headerColor =
    Color.lerp(widget.activeColor, Colors.black, 0.10)!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _isExpanded ? headerColor : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: true,
          onExpansionChanged: (expanded) {
            setState(() {
              _isExpanded = expanded;
            });
          },
          iconColor: Colors.white,
          collapsedIconColor: AppColors.textHeadingBlack,
          tilePadding: const EdgeInsets.symmetric(
              horizontal: 20, vertical: 5),
          title: Text(
            (widget.chapter['title'] ?? "Untitled Chapter")
                .toString()
                .toUpperCase(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _isExpanded
                  ? Colors.white
                  : AppColors.textHeadingBlack,
            ),
          ),
          children: [
            Container(
              decoration: BoxDecoration(
                color: widget.activeColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              padding:
              const EdgeInsets.fromLTRB(15, 15, 15, 20),
              child: Row(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // Image Section
                  Expanded(
                    flex: 5,
                    child: ClipRRect(
                      borderRadius:
                      BorderRadius.circular(8),
                      child: widget.chapter['image'] != null &&
                          widget.chapter['image']
                              .toString()
                              .isNotEmpty
                      // 🔹 REPLACED Image.network with CachedNetworkImage
                          ? CachedNetworkImage(
                        imageUrl: widget.chapter['image'],
                        fit: BoxFit.cover,
                        height: imageHeight,
                        width: double.infinity,
                        placeholder: (context, url) => Container(
                          height: imageHeight,
                          color: Colors.white10,
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: imageHeight,
                          color: Colors.white10,
                          child: const Icon(
                            Icons.image_not_supported,
                            color: Colors.white,
                          ),
                        ),
                      )
                          : Container(
                        height: imageHeight,
                        color: Colors.white10,
                        child: const Icon(
                          Icons.image,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(width: width * 0.03),

                  // Buttons Section
                  Expanded(
                    flex: 6,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPillButton(
                          context,
                          icon: Icons.edit_note_rounded,
                          label: "Notes",
                          bgColor:
                          const Color(0xFFB3E5FC),
                          iconBg:
                          const Color(0xFF4FC3F7),
                          isEnabled:
                          widget.chapter['notes'] ==
                              true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  NotesListingPage(
                                    chapterId: widget
                                        .chapter['id']
                                        .toString(),
                                    chapterTitle: widget
                                        .chapter['title']
                                        .toString(),
                                  ),
                            ),
                          ),
                        ),
                        SizedBox(height: width * 0.02),
                        _buildPillButton(
                          context,
                          icon: Icons.menu_book_rounded,
                          label: "Solutions",
                          bgColor:
                          const Color(0xFFFFE0B2),
                          iconBg:
                          const Color(0xFFFFB74D),
                          isEnabled: widget
                              .chapter['solutions'] ==
                              true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChapterSolutionsPage(
                                    subjectId:
                                    widget.subjectId,
                                    chapterId: widget
                                        .chapter['id']
                                        .toString(),
                                    chapterTitle: widget
                                        .chapter['title'],
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: width * 0.02),

                  // Video Button Section
                  _buildVideoCircle(
                    context,
                    isEnabled:
                    widget.chapter['videos'] ==
                        true,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            VideoListingPage(
                              chapterTitle:
                              widget.chapter['title'] ??
                                  "Videos",
                              chapterId: widget
                                  .chapter['id']
                                  .toString(),
                              subjectName:
                              widget.subjectName,
                            ),
                      ),
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

  Widget _buildPillButton(
      BuildContext context, {
        required IconData icon,
        required String label,
        required Color bgColor,
        required Color iconBg,
        required bool isEnabled,
        required VoidCallback onTap,
      }) {
    final width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius:
            BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: width * 0.035,
                backgroundColor: iconBg,
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: width * 0.04,
                ),
              ),
              SizedBox(width: width * 0.025),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow:
                  TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.032,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCircle(
      BuildContext context, {
        required bool isEnabled,
        required VoidCallback onTap,
      }) {
    final width = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.4,
        child: CircleAvatar(
          radius: width * 0.06,
          backgroundColor:
          const Color(0xFFFFCCBC),
          child: Icon(
            Icons.play_arrow_rounded,
            color: Colors.deepOrange.shade400,
            size: width * 0.08,
          ),
        ),
      ),
    );
  }
}