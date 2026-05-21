import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // 🔹 Import shimmer package
import 'widgets.dart/appbar_page.dart';
import 'services/student_service.dart';
import 'chapter_solution_details.dart';
import 'package:glapod/utils/app_colors.dart';
import 'widgets.dart/empty_state_widget.dart';
import 'storage/local_storage_service.dart';

// --- SHIMMER PLACEHOLDER WIDGET ---
class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ChapterSolutionsPage extends StatefulWidget {
  final String chapterTitle;
  final String subjectId;
  final String chapterId;

  const ChapterSolutionsPage({
    super.key,
    required this.subjectId,
    required this.chapterId,
    required this.chapterTitle
  });

  @override
  State<ChapterSolutionsPage> createState() => _ChapterSolutionsPageState();
}

class _ChapterSolutionsPageState extends State<ChapterSolutionsPage> {
  late Future<Map<String, dynamic>> _solutionsFuture;

  @override
  void initState() {
    super.initState();
    _solutionsFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final studentData = await LocalStorageService.getStudent();
    final String classId = studentData?['class_id']?.toString() ?? "3";
    return StudentService.getChapterSolutions(classId, widget.subjectId, widget.chapterId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: CustomAppBar(
        height: 40,
        title: widget.chapterTitle,
        isDashboard: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _solutionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerList(); // 🔹 Replaced Spinner with Shimmer
          }

          if (snapshot.hasError || !snapshot.hasData || snapshot.data!['status'] != true) {
            return const EmptyStateWidget(msg: "No solutions found!");
          }

          final solutions = snapshot.data!['data'] as List? ?? [];

          if (solutions.isEmpty) {
            return const EmptyStateWidget(msg: "No solutions available for this chapter.");
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            itemCount: solutions.length,
            itemBuilder: (context, index) => _buildSolutionCard(context, solutions[index]),
          );
        },
      ),
    );
  }

  // 🔹 Added Shimmer Skeleton List
  Widget _buildShimmerList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      itemCount: 6, // Show 6 skeleton items
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    // Skeleton for Title
                    ShimmerPlaceholder(width: 120, height: 20),
                    SizedBox(height: 8),
                    // Skeleton for Subtitle
                    ShimmerPlaceholder(width: 80, height: 14),
                  ],
                ),
              ),
              // Skeleton for Arrow Icon
              const ShimmerPlaceholder(width: 18, height: 18, borderRadius: 4),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSolutionCard(BuildContext context, dynamic item) {
    final String title = item['activity'] != null ? "Activity ${item['activity']}" : "Solution";
    final String pageNum = item['page_number']?.toString() ?? "N/A";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChapterSolutionDetailsPage(
              exerciseTitle: title,
              qaList: [
                {
                  "question": item['question'] ?? "",
                  "answer": item['answer'] ?? "",
                }
              ],
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.textHeadingBlack,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Page No. $pageNum",
                    style: const TextStyle(color: AppColors.textSubtitle, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 18,
              color: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }
}