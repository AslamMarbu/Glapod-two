import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../providers/question_view_provider.dart';
import '../utils/share_helper.dart';
import 'widgets.dart/appbar_page.dart';

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
    // Call directly to ensure data is set before the first build
    context.read<QuestionViewProvider>().setInitialData(
      widget.qaList,
      widget.initialIndex,
    );
  }

  // --- CRITICAL FIX: CLEAR DATA ON EXIT ---
  @override
  void dispose() {
    // This clears the provider memory so the next set of questions starts fresh
    context.read<QuestionViewProvider>().disposeData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qv = context.watch<QuestionViewProvider>();
    final currentQA = qv.currentQA;
    bool isLoading = currentQA == null;

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: CustomAppBar(
        height: 40,
        title: isLoading ? widget.title : "${widget.title} - Q${qv.currentIndex + 1}",
        actionRequired: !isLoading,
        postId: isLoading ? null : currentQA['id'],
        bookmarkType: "question_bank",
        initialBookmarked: isLoading ? false : (currentQA['bookmark'] ?? false),
        onBookmarkChanged: (bool newValue) => qv.updateBookmark(newValue),
        shareText: isLoading
            ? ""
            : ShareHelper.getQuestionShareText(
          question: qv.cleanHtml(currentQA['question'] ?? ""),
          answer: qv.cleanHtml(currentQA['answer'] ?? ""),
        ),
      ),
      body: isLoading ? _buildShimmerBody() : _buildContent(qv, currentQA),
    );
  }

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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Question"),
                    const SizedBox(height: 15),
                    _renderHtmlWithMath(currentQA['question'] ?? "", 18),
                    if (qv.showAnswer) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Container(height: 2, color: Colors.white),
                      ),
                      _buildSectionHeader("Answer"),
                      const SizedBox(height: 10),
                      _renderHtmlWithMath(currentQA['answer'] ?? "", 17),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        _buildNavRow(qv),
      ],
    );
  }

  Widget _renderHtmlWithMath(String htmlData, double baseFontSize) {
    return HtmlWidget(
      htmlData,
      textStyle: TextStyle(
          fontSize: baseFontSize,
          color: const Color(0xFF263238),
          height: 1.5),
      customWidgetBuilder: (element) {
        final text = element.text;
        if (text.contains(r'\(') || text.contains(r'\[')) {
          final cleanMath = text
              .replaceAll(r'\(', '')
              .replaceAll(r'\)', '')
              .replaceAll(r'\[', '')
              .replaceAll(r'\]', '');

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Math.tex(
              cleanMath,
              textStyle: TextStyle(fontSize: baseFontSize + 1),
              onErrorFallback: (err) => Text(text),
            ),
          );
        }
        return null;
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF1B75BB),
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  Widget _buildNavRow(QuestionViewProvider qv) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _navButton("Prev", Icons.arrow_back_ios_new, qv.currentIndex > 0,
                  () => qv.previousQuestion()),
          const SizedBox(width: 20),
          _navButton("Next", Icons.arrow_forward_ios,
              qv.currentIndex < qv.qaList.length - 1, () => qv.nextQuestion()),
        ],
      ),
    );
  }

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
              ? const LinearGradient(colors: [Color(0xFF1B75BB), Color(0xFF6BCF2E)])
              : null,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF1B75BB),
            fontWeight: FontWeight.bold,
          ),
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
        ),
        child: Row(
          children: [
            if (label == "Prev")
              Icon(icon, size: 14, color: enabled ? const Color(0xFF1B75BB) : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: enabled ? const Color(0xFF1B75BB) : Colors.grey,
              ),
            ),
            if (label == "Next") ...[
              const SizedBox(width: 8),
              Icon(icon, size: 14, color: enabled ? const Color(0xFF1B75BB) : Colors.grey)
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerBody() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShimmerPlaceholder(width: 130, height: 50, borderRadius: 25),
            SizedBox(width: 20),
            ShimmerPlaceholder(width: 130, height: 50, borderRadius: 25),
          ],
        ),
        const SizedBox(height: 25),
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
                ShimmerPlaceholder(width: 200, height: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}

class ShimmerPlaceholder extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  const ShimmerPlaceholder(
      {super.key, required this.width, required this.height, this.borderRadius = 8});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(borderRadius)),
      ),
    );
  }
}