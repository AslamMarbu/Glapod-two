import 'package:flutter/material.dart';
import 'package:glapod/utils/share_helper.dart';
import 'widgets.dart/appbar_page.dart';
import 'package:glapod/utils/app_colors.dart';

class ChapterSolutionDetailsPage extends StatefulWidget {
  final String exerciseTitle;
  final List qaList;
  final int initialIndex;

  const ChapterSolutionDetailsPage({
    super.key,
    required this.exerciseTitle,
    required this.qaList,
    this.initialIndex = 0,
  });

  @override
  State<ChapterSolutionDetailsPage> createState() => _ChapterSolutionDetailsPageState();
}

class _ChapterSolutionDetailsPageState extends State<ChapterSolutionDetailsPage> {
  late int _currentIndex;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _handleBookmarkUpdate(bool isBookmarked) {
    setState(() {
      widget.qaList[_currentIndex]['bookmark'] = isBookmarked;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.qaList.isEmpty) {
      return Scaffold(
        appBar: CustomAppBar(title: widget.exerciseTitle, height: 60, isDashboard: false),
        body: const Center(child: Text("No questions found")),
      );
    }

    final currentQA = widget.qaList[_currentIndex];

    String cleanQuestion = (currentQA['question'] ?? "").replaceAll(RegExp(r'<[^>]*>'), '');
    String cleanAnswer = (currentQA['answer'] ?? "").replaceAll(RegExp(r'<[^>]*>'), '');

    return Scaffold(
      backgroundColor: const Color(0xFFF1FAF2),
      appBar: CustomAppBar(
        key: ValueKey("sol_appbar_${currentQA['id']}_${currentQA['bookmark']}"),
        height: 40,
        title: "${widget.exerciseTitle} - Q${_currentIndex + 1}",
        actionRequired: true,
        isDashboard: false,
        postId: currentQA['id'],
        bookmarkType: "textbook_solutions",
        initialBookmarked: currentQA['bookmark'] ?? false,
        onBookmarkChanged: (bool newValue) {
          _handleBookmarkUpdate(newValue);
        },
        shareText:ShareHelper.getQuestionShareText(
          question: currentQA['question'] ?? "",
          answer: currentQA['answer'] ?? "",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Column(
          children: [
            // Toggle Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                _toggleButton("Hide Ans", !_showAnswer, () => setState(() => _showAnswer = false)),
                 const SizedBox(width: 15),
                _toggleButton("Show Ans", _showAnswer, () => setState(() => _showAnswer = true)),

              ],
            ),
            const SizedBox(height: 20),

            // Question & Answer Card
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF1B75BB).withOpacity(0.22),
                      const Color(0xFF6BCF2E).withOpacity(0.22),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    )
                  ],
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          currentQA['title'] ?? "Question",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1B75BB),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        currentQA['question'].replaceAll(RegExp(r'<[^>]*>'), ''),
                        style: const TextStyle(
                          fontSize: 17,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF263238),
                        ),
                      ),

                      if (_showAnswer) ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Divider(color: Colors.white, thickness: 1.5),
                        ),
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: Color(0xFF1B75BB), size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Answer",
                              style: TextStyle(
                                color: Color(0xFF1B75BB),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          currentQA['answer'].replaceAll(RegExp(r'<[^>]*>'), ''),
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Navigation Buttons (Prev/Next)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _navButton(
                  label: "Prev",
                  icon: Icons.arrow_back_ios_new,
                  enabled: _currentIndex > 0,
                  onTap: () {
                    setState(() {
                      _currentIndex--;
                      // Logic: _showAnswer remains whatever it is (persist state)
                    });
                  },
                ),
                const SizedBox(width: 25),
                _navButton(
                  label: "Next",
                  icon: Icons.arrow_forward_ios,
                  enabled: _currentIndex < widget.qaList.length - 1,
                  onTap: () {
                    setState(() {
                      _currentIndex++;
                      // Logic: _showAnswer remains whatever it is (persist state)
                    });
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleButton(String text, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive ? const LinearGradient(colors: [Color(0xFF1B75BB), Color(0xFF6BCF2E)]) : null,
          color: isActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 3))
          ],
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

  Widget _navButton({required String label, required IconData icon, required bool enabled, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: enabled ? onTap : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B75BB),
        elevation: 3,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label == "Prev") Icon(icon, size: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          if (label == "Next") Icon(icon, size: 16),
        ],
      ),
    );
  }
}