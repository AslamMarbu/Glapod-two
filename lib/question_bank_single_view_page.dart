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
  bool _showAnswer = false;
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        height: 40,
        title: isLoading
            ? widget.title
            : "${widget.title} - Q${qv.currentIndex + 1}",
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
    return SafeArea(
      child: Column(
        children: [
          const SizedBox(height: 18),

          _buildProgress(qv),

          const SizedBox(height: 20),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18),

              children: [
                _buildQuestionCard(currentQA),

                const SizedBox(height: 18),

                _buildAnswerToggle(),

                const SizedBox(height: 18),

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 300),

                  crossFadeState: _showAnswer
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,

                  firstChild: const SizedBox(),

                  secondChild: _buildAnswerCard(currentQA),
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),

          _buildNavigation(qv),

          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Widget _buildProgress(QuestionViewProvider qv) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),

      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),

            decoration: BoxDecoration(
              color: Colors.white,

              borderRadius: BorderRadius.circular(30),

              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 15),
              ],
            ),

            child: Text(
              "Question ${qv.currentIndex + 1} of ${qv.qaList.length}",

              style: const TextStyle(
                fontWeight: FontWeight.bold,

                fontSize: 18,

                color: Color(0xff4F46E5),
              ),
            ),
          ),

          const SizedBox(height: 15),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),

            child: LinearProgressIndicator(
              minHeight: 8,

              value: (qv.currentIndex + 1) / qv.qaList.length,

              backgroundColor: Colors.grey.shade300,

              valueColor: const AlwaysStoppedAnimation(Color(0xff4F46E5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(dynamic currentQA) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Header
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: Color(0xFF4F46E5),
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              const Expanded(
                child: Text(
                  "Question",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          _renderHtmlWithMath(currentQA['question'] ?? "", 18),
        ],
      ),
    );
  }

  Widget _buildAnswerToggle() {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {
        setState(() {
          _showAnswer = !_showAnswer;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _showAnswer ? const Color(0xFF10B981) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: const Color(0xFF10B981), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 12),
          ],
        ),
        child: Row(
          children: [
            Icon(
              _showAnswer
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: _showAnswer ? Colors.white : const Color(0xFF10B981),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                _showAnswer ? "Hide Answer" : "Show Answer",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: _showAnswer ? Colors.white : const Color(0xFF10B981),
                ),
              ),
            ),

            AnimatedRotation(
              turns: _showAnswer ? .5 : 0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _showAnswer ? Colors.white : const Color(0xFF10B981),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnswerCard(dynamic currentQA) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                ),
              ),

              const SizedBox(width: 14),

              const Text(
                "Answer",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _renderHtmlWithMath(currentQA['answer'] ?? "", 18),
        ],
      ),
    );
  }

  Widget _renderHtmlWithMath(String htmlData, double baseFontSize) {
    return HtmlWidget(
      htmlData,
      textStyle: TextStyle(
        fontSize: baseFontSize + 1,
        color: const Color(0xFF263238),
        height: 1.8,
      ),
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
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Math.tex(
              cleanMath,
              textStyle: TextStyle(fontSize: baseFontSize + 2),
            ),
          );
        }
        return null;
      },
    );
  }

  Widget _buildNavigation(QuestionViewProvider qv) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: [
          /// Previous
          Expanded(
            child: SizedBox(
              height: 55,
              child: OutlinedButton.icon(
                onPressed: qv.currentIndex > 0
                    ? () {
                        setState(() {
                          _showAnswer = false;
                        });
                        qv.previousQuestion();
                      }
                    : null,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                label: const Text("Previous"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4F46E5),
                  side: BorderSide(
                    color: qv.currentIndex > 0
                        ? const Color(0xFF4F46E5)
                        : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 15),

          /// Next
          Expanded(
            child: SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: qv.currentIndex < qv.qaList.length - 1
                    ? () {
                        setState(() {
                          _showAnswer = false;
                        });
                        qv.nextQuestion();
                      }
                    : null,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text("Next"),
                iconAlignment: IconAlignment.end,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ),
        ],
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
