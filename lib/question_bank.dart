import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/question_bank_provider.dart';
import '../utils/app_colors.dart';
import 'widgets.dart/appbar_page.dart';
import 'question_bank_single_view_page.dart';

// --- Shimmer Placeholder Widget ---
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
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
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

// --- Question Bank Page ---
class QuestionBankPage extends StatefulWidget {
  final String subjectName;
  final String subjectId;
  final String classId;

  const QuestionBankPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.classId,
  });

  @override
  State<QuestionBankPage> createState() => _QuestionBankPageState();
}

class _QuestionBankPageState extends State<QuestionBankPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<QuestionBankProvider>().fetchInitialData(
          widget.subjectId,
          widget.classId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5FFF7),
        appBar: CustomAppBar(
          height: 40,
          title: widget.subjectName,
          bottom: _buildTabBar(),
        ),
        body: Consumer<QuestionBankProvider>(
          builder: (context, qbProvider, child) {
            if (qbProvider.isLoading) {
              return _buildShimmerLoading(width);
            }

            return TabBarView(
              children: [
                _buildTabList(qbProvider.chapterList, true),
                _buildTabList(qbProvider.markList, false),
              ],
            );
          },
        ),
      ),
    );
  }

  // 🔹 Shimmer Loading
  Widget _buildShimmerLoading(double width) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (_, __) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
                  children: [
                    ShimmerPlaceholder(
                      width: width * 0.5,
                      height: width * 0.045,
                    ),
                    SizedBox(height: width * 0.02),
                    ShimmerPlaceholder(
                      width: width * 0.2,
                      height: width * 0.035,
                    ),
                  ],
                ),
              ),
              ShimmerPlaceholder(
                width: width * 0.04,
                height: width * 0.04,
                borderRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(50),
      child: Padding(
        padding: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        child: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: "BY CHAPTER"),
            Tab(text: "BY MARKS"),
          ],
        ),
      ),
    );
  }

  Widget _buildTabList(List<dynamic> list, bool isChapter) {
    if (list.isEmpty) {
      return const Center(child: Text("No questions available"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      cacheExtent: 120, // 🔹 slightly improved preloading
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];

        final String title = isChapter
            ? (item['chapter_title'] ?? "Untitled")
            : "Mark: ${item['mark']}";

        return _buildQBankCard(
          title,
          "${item['question_count']} Questions",
          onTap: () => _onCardTap(item, isChapter, title),
        );
      },
    );
  }

  Future<void> _onCardTap(
      dynamic item, bool isChapter, String title) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    final questions =
    await context.read<QuestionBankProvider>().fetchQuestionSet(
      isChapter: isChapter,
      subjectId: widget.subjectId,
      classId: widget.classId,
      item: item,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (questions != null && questions.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => QuestionViewPage(
            title: title,
            qaList: questions,
            initialIndex: 0,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not retrieve questions."),
        ),
      );
    }
  }

  Widget _buildQBankCard(
      String title,
      String subtitle, {
        required VoidCallback onTap,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: onTap,
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis, // 🔹 prevents overflow
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: AppColors.textHeadingBlack,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSubtitle,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey,
        ),
      ),
    );
  }
}