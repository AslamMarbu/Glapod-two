import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/question_view_provider.dart';
import '../utils/share_helper.dart';
import 'widgets.dart/appbar_page.dart';

// --- SHIMMER PLACEHOLDER ---
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

class QuestionViewPage extends StatefulWidget {
  final String title;
  final List<dynamic> qaList;
  final int initialIndex;

  const QuestionViewPage({
    super.key,
    required this.title,
    required this.qaList,
    this.initialIndex = 0,
  });

  @override
  State<QuestionViewPage> createState() => _QuestionViewPageState();
}

class _QuestionViewPageState extends State<QuestionViewPage> {
  @override
  void initState() {
    super.initState();
    context.read<QuestionViewProvider>().setInitialData(
      widget.qaList,
      widget.initialIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final qv = context.watch<QuestionViewProvider>();
    final currentQA = qv.currentQA;

    // Use a skeleton if currentQA is null or if you have an isLoading flag in your provider
    bool isLoading = currentQA == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: CustomAppBar(
        height: 40,
        title: isLoading ? widget.title : "${widget.title} - Q${qv.currentIndex + 1}",
        actionRequired: !isLoading,
        isDashboard: false,
        postId: isLoading ? null : currentQA['id'],
        bookmarkType: "question_bank",
        initialBookmarked: isLoading ? false : (currentQA['bookmark'] ?? false),
        onBookmarkChanged: (bool newValue) => qv.updateBookmark(newValue),
        shareText: isLoading
            ? ""
            : ShareHelper.getQuestionShareText(
          question: currentQA['question'] ?? "",
          answer: currentQA['answer'] ?? "",
        ),
      ),
      body: isLoading ? _buildShimmerBody() : _buildContent(qv, currentQA),
    );
  }

  // --- ACTUAL CONTENT BODY ---
  Widget _buildContent(QuestionViewProvider qv, dynamic currentQA) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _toggleButton("Hide Ans", !qv.showAnswer, () => qv.toggleAnswer(false)),
            const SizedBox(width: 20),
            _toggleButton("Show Ans", qv.showAnswer, () => qv.toggleAnswer(true)),
          ],
        ),
        const SizedBox(height: 25),
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1B75BB).withOpacity(0.18),
                  const Color(0xFF6BCF2E).withOpacity(0.18)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white, width: 2.5),
            ),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _tagLabel("Question"),
                  const SizedBox(height: 20),
                  Text(
                    qv.cleanHtml(currentQA['question']),
                    style: const TextStyle(
                      fontSize: 18,
                      height: 1.5,
                      color: Color(0xFF263238),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (qv.showAnswer) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Divider(color: Colors.white, thickness: 2),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF1B75BB), size: 22),
                        SizedBox(width: 10),
                        Text("Answer",
                            style: TextStyle(
                                color: Color(0xFF1B75BB),
                                fontWeight: FontWeight.bold,
                                fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      qv.cleanHtml(currentQA['answer']),
                      style: const TextStyle(fontSize: 17, height: 1.6, color: Colors.black87),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _navButton("Prev", Icons.arrow_back_ios_new, qv.currentIndex > 0, () => qv.previousQuestion()),
              const SizedBox(width: 20),
              _navButton("Next", Icons.arrow_forward_ios, qv.currentIndex < qv.qaList.length - 1, () => qv.nextQuestion()),
            ],
          ),
        ),
      ],
    );
  }

  // --- SHIMMER SKELETON BODY ---
  Widget _buildShimmerBody() {
    return Column(
      children: [
        const SizedBox(height: 20),
        // Toggle Buttons Shimmer
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShimmerPlaceholder(width: 130, height: 50, borderRadius: 25),
            SizedBox(width: 20),
            ShimmerPlaceholder(width: 130, height: 50, borderRadius: 25),
          ],
        ),
        const SizedBox(height: 25),
        // Main Card Shimmer
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShimmerPlaceholder(width: 100, height: 35, borderRadius: 10),
                SizedBox(height: 30),
                ShimmerPlaceholder(width: double.infinity, height: 20),
                SizedBox(height: 12),
                ShimmerPlaceholder(width: double.infinity, height: 20),
                SizedBox(height: 12),
                ShimmerPlaceholder(width: 200, height: 20),
              ],
            ),
          ),
        ),
        // Nav Buttons Shimmer
        const Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShimmerPlaceholder(width: 100, height: 45, borderRadius: 30),
              SizedBox(width: 20),
              ShimmerPlaceholder(width: 100, height: 45, borderRadius: 30),
            ],
          ),
        ),
      ],
    );
  }

  // ... (Toggle Button, Nav Button, Tag Label helpers remain exactly the same)
  Widget _toggleButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? null : Colors.white,
          gradient: isActive
              ? const LinearGradient(
              colors: [Color(0xFF1B75BB), Color(0xFF6BCF2E)])
              : null,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF1B75BB),
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
      ),
    );
  }

  Widget _navButton(String label, IconData icon, bool enabled, VoidCallback onTap) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            if (enabled)
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label == "Prev")
              Icon(icon, size: 14, color: enabled ? const Color(0xFF1B75BB) : Colors.grey),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: enabled ? const Color(0xFF1B75BB) : Colors.grey)),
            const SizedBox(width: 8),
            if (label == "Next")
              Icon(icon, size: 14, color: enabled ? const Color(0xFF1B75BB) : Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _tagLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10)),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.bold, color: Color(0xFF1B75BB))),
    );
  }
}