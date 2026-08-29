import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/spelling_quiz_provider.dart';

class QuizGamePage extends StatefulWidget {
  final String level;

  const QuizGamePage({
    super.key,
    required this.level,
  });

  @override
  State<QuizGamePage> createState() => _QuizGamePageState();
}

class _QuizGamePageState extends State<QuizGamePage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SpellingQuizProvider>(
        context,
        listen: false,
      ).loadQuiz(widget.level);
    });
  }

  void showResult(SpellingQuizProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: const Text(
            "🎉 Quiz Completed",
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Your Score",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "${provider.score}",
                style: const TextStyle(
                  fontSize: 45,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(context);
                  provider.restart();
                },
                child: const Text(
                  "Play Again",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLevelMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(30),
        ),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Select Difficulty",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _levelTile("beginner", " Beginner"),
              _levelTile("intermediate", " Intermediate"),
              _levelTile("advanced", " Advanced"),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SpellingQuizProvider>(context);

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (provider.quizzes.isEmpty) {
      return const Scaffold(
        body: Center(
          child: Text("No Questions Found"),
        ),
      );
    }

    // Progress Calculations
    final int totalQuestions = provider.quizzes.length;
    final int currentIdx = provider.currentQuestion;
    final double progressPercent = totalQuestions > 0 ? (currentIdx + 1) / totalQuestions : 0.0;
    final int displayPercent = (progressPercent * 100).toInt();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFFDF9),
              Color(0xFFFFF5E6),
            ],
          ),
        ),
        child: SafeArea(
          top: false, 
          child: Column(
            children: [
              /// DYNAMIC HEADER BACKGROUND WITH ACCENT GRADIENT
              Container(
                padding: const EdgeInsets.fromLTRB(16, 50, 20, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "📝 Spelling Quiz",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _showLevelMenu,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.18),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white24,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.level[0].toUpperCase() + widget.level.substring(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFFFC107), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            "${provider.score}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF212121),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              /// MAIN QUIZ CONTENTS
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),

                      
                      

                      /// QUESTION CARD WITH LEFT SIDE ILLUSTRATION BLOCK
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.deepPurple.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.assignment_outlined,
                                color: Colors.deepPurple,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                "Which one is the correct spelling?",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1C24),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      /// OPTION CHIPS LIST
                      Expanded(
                        child: ListView.builder(
                          itemCount: provider.currentOptions.length,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            bool isSelected = provider.answered && index == provider.selectedIndex;
                            bool isCorrectAnswer = provider.answered && provider.isCorrect(index);

                            Color borderColor = Colors.transparent;
                            Color cardColor = Colors.white;

                            if (provider.answered) {
                              if (isCorrectAnswer) {
                                borderColor = Colors.green;
                                cardColor = Colors.green.withOpacity(0.05);
                              } else if (isSelected) {
                                borderColor = Colors.red;
                                cardColor = Colors.red.withOpacity(0.05);
                              }
                            } else if (isSelected) {
                              borderColor = Colors.deepPurple;
                            }

                            return GestureDetector(
                              onTap: () {
                                if (!provider.answered) {
                                  provider.checkAnswer(index);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: borderColor != Colors.transparent 
                                        ? borderColor 
                                        : Colors.grey.shade100,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isCorrectAnswer 
                                          ? Colors.green 
                                          : (isSelected && provider.answered ? Colors.red : Colors.deepPurple),
                                      child: Text(
                                        String.fromCharCode(65 + index),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        provider.currentOptions[index],
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF2D3142),
                                        ),
                                      ),
                                    ),
                                    if (provider.answered && isCorrectAnswer)
                                      const Icon(Icons.check_circle, color: Colors.green)
                                    else if (provider.answered && isSelected)
                                      const Icon(Icons.cancel, color: Colors.red),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      /// GRADIENT ACTION CALL BOTTOM BUTTON
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: provider.answered
                                ? const LinearGradient(
                                    colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  )
                                : null,
                            color: !provider.answered ? Colors.grey.shade300 : null,
                            boxShadow: provider.answered
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFF8F00).withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ]
                                : [],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            onPressed: provider.answered
                                ? () {
                                    bool hasNext = provider.nextQuestion();
                                    if (!hasNext) {
                                      showResult(provider);
                                    }
                                  }
                                : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  provider.currentQuestion == totalQuestions - 1
                                      ? "Finish Quiz"
                                      : "Next Question",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: provider.answered ? Colors.white : Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward,
                                  color: provider.answered ? Colors.white : Colors.grey.shade500,
                                  size: 20,
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _levelTile(String level, String title) {
    return ListTile(
      title: Text(title),
      trailing: widget.level == level
          ? const Icon(
              Icons.check_circle,
              color: Colors.green,
            )
          : null,
      onTap: () {
        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuizGamePage(
              level: level,
            ),
          ),
        );
      },
    );
  }
}