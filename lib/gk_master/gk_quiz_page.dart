import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gk_master_model.dart';
import '../providers/gk_master_provider.dart';

class GkQuizPage extends StatefulWidget {
  const GkQuizPage({super.key});

  @override
  State<GkQuizPage> createState() => _GkQuizPageState();
}

class _GkQuizPageState extends State<GkQuizPage> {
  static const Color _primaryText = Color(0xFF1F2937);
  static const Color _secondaryText = Color(0xFF667085);
  static const Color _accentColor = Color(0xFF5B4BEB);

  static const Color _correctColor = Color(0xFF22C55E);
  static const Color _correctBackground = Color(0xFFEAF8EF);

  static const Color _wrongColor = Color(0xFFEF4444);
  static const Color _wrongBackground = Color(0xFFFDECEC);

  static const TextStyle _buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToExplanation() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 120));

      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final double target = _scrollController.position.maxScrollExtent;

      await _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GkProvider>(
      builder: (context, provider, child) {
        final question = provider.currentQuestion;

        if (question == null) {
          return const Scaffold(
            body: Center(child: Text('No questions available')),
          );
        }

        final String? selectedAnswer = provider.selectedAnswers[question.id];

        final bool isAnswered = provider.isQuestionAnswered(question.id);

        return Scaffold(
          backgroundColor: const Color(0xFFF7F8FA),

          body: Column(
            children: [
              _quizHeader(context, provider),

              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 22, 18, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _questionCard(provider, question.question),

                      const SizedBox(height: 18),

                      ...question.options.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _optionCard(
                            optionKey: entry.key,
                            optionText: entry.value,
                            selectedAnswer: selectedAnswer,
                            correctAnswer: question.correctAnswer,
                            isAnswered: isAnswered,
                            onTap: () {
                              if (isAnswered) return;

                              provider.selectAnswer(entry.key);
                              _scrollToExplanation();
                            },
                          ),
                        );
                      }),

                      if (isAnswered) ...[
                        const SizedBox(height: 8),

                        _answerStatusCard(
                          selectedAnswer: selectedAnswer,
                          correctAnswer: question.correctAnswer,
                        ),

                        const SizedBox(height: 14),

                        _explanationCard(question.answerExplanation),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          bottomNavigationBar: _bottomButton(context, provider, isAnswered),
        );
      },
    );
  }

  Widget _quizHeader(BuildContext context, GkProvider provider) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B4BEB), Color(0xFF8B6EF3)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(50),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    provider.selectedCategory?.name ?? 'Quiz Master',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: Colors.white,
                    size: 23,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _quizProgressHeader(GkProvider provider) {
    final int currentNumber = provider.currentQuestionIndex + 1;
    final int totalQuestions = provider.questions.length;

    final double progress = totalQuestions > 0
        ? currentNumber / totalQuestions
        : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7E7F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0EDFF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  provider.selectedLevel?.toUpperCase() ?? '',
                  style: const TextStyle(
                    color: _accentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
              ),

              const Spacer(),

              Text(
                '$currentNumber / $totalQuestions',
                style: const TextStyle(
                  color: _secondaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Text(
                'Question $currentNumber',
                style: const TextStyle(
                  color: _primaryText,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const Spacer(),

              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: _accentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 9),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFE9E7F8),
              valueColor: const AlwaysStoppedAnimation<Color>(_accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _questionCard(GkProvider provider, String question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAECF0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A101828),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline_rounded, color: _accentColor, size: 19),

              SizedBox(width: 7),

              Text(
                'CHOOSE THE CORRECT ANSWER',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _accentColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            question,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _primaryText,
              height: 1.45,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionCard({
    required String optionKey,
    required String optionText,
    required String? selectedAnswer,
    required String correctAnswer,
    required bool isAnswered,
    required VoidCallback onTap,
  }) {
    final bool isSelected = selectedAnswer == optionKey;

    final bool isCorrectOption = optionKey == correctAnswer;

    final bool selectedWrong = isAnswered && isSelected && !isCorrectOption;

    Color backgroundColor = Colors.white;
    Color borderColor = const Color(0xFFE4E7EC);
    Color letterBackground = const Color(0xFFF2F4F7);
    Color letterColor = const Color(0xFF475467);

    IconData? trailingIcon;
    Color trailingColor = _secondaryText;

    if (isAnswered && isCorrectOption) {
      backgroundColor = _correctBackground;
      borderColor = _correctColor;
      letterBackground = _correctColor;
      letterColor = Colors.white;
      trailingIcon = Icons.check_circle_rounded;
      trailingColor = _correctColor;
    } else if (selectedWrong) {
      backgroundColor = _wrongBackground;
      borderColor = _wrongColor;
      letterBackground = _wrongColor;
      letterColor = Colors.white;
      trailingIcon = Icons.cancel_rounded;
      trailingColor = _wrongColor;
    } else if (isSelected) {
      backgroundColor = const Color(0xFFF0EDFF);
      borderColor = _accentColor;
      letterBackground = _accentColor;
      letterColor = Colors.white;
      trailingIcon = Icons.check_circle_rounded;
      trailingColor = _accentColor;
    }

    final String label = optionKey.replaceFirst('option_', '').toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isAnswered ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isAnswered || isSelected ? 1.7 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08101828),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: letterBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: letterColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  optionText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _primaryText,
                    height: 1.4,
                  ),
                ),
              ),

              if (trailingIcon != null) ...[
                const SizedBox(width: 10),

                Icon(trailingIcon, color: trailingColor, size: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _answerStatusCard({
    required String? selectedAnswer,
    required String correctAnswer,
  }) {
    final bool isCorrect = selectedAnswer == correctAnswer;

    final Color color = isCorrect ? _correctColor : _wrongColor;

    final Color background = isCorrect ? _correctBackground : _wrongBackground;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.40)),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: color,
            size: 25,
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Text(
              isCorrect
                  ? 'Correct! Well done.'
                  : 'Incorrect. The correct answer is highlighted.',
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _explanationCard(String explanation) {
    final String text = explanation.trim().isEmpty
        ? 'No explanation is available for this question.'
        : explanation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B), size: 23),

              SizedBox(width: 9),

              Text(
                'Explanation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.6,
              color: Color(0xFF713F12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomButton(
    BuildContext context,
    GkProvider provider,
    bool isAnswered,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 16,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: !isAnswered || provider.isSubmitting
                ? null
                : () async {
                    if (provider.isLastQuestion) {
                      final result = await provider.submitQuiz();

                      if (!context.mounted) {
                        return;
                      }

                      if (result != null) {
                        _showResultDialog(context, result);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              provider.errorMessage ??
                                  'Quiz submission failed.',
                            ),
                          ),
                        );
                      }
                    } else {
                      provider.nextQuestion();

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (!_scrollController.hasClients) {
                          return;
                        }

                        _scrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentColor,
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFD8D5F5),
              disabledForegroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: provider.isSubmitting
                ? const SizedBox(
                    width: 23,
                    height: 23,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        !isAnswered
                            ? 'Select an Answer'
                            : provider.isLastQuestion
                            ? 'Finish Quiz'
                            : 'Next Question',
                        style: _buttonTextStyle,
                      ),

                      if (isAnswered) ...[
                        const SizedBox(width: 9),

                        Icon(
                          provider.isLastQuestion
                              ? Icons.done_all_rounded
                              : Icons.arrow_forward_rounded,
                          size: 22,
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  void _showResultDialog(BuildContext context, Map<String, dynamic> response) {
    final rawData = response['data'];

    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};

    final int correct = int.tryParse('${data['correct'] ?? 0}') ?? 0;

    final int total = int.tryParse('${data['total_questions'] ?? 0}') ?? 0;

    final double percentage = total > 0 ? (correct / total) * 100 : 0;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE8A3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFFFFA000),
                    size: 44,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Great Job!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _primaryText,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '$correct / $total',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: _accentColor,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  '${percentage.toStringAsFixed(0)}% Accuracy',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _secondaryText,
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    _resultBox(
                      title: 'Correct',
                      value: '${data['correct'] ?? 0}',
                      icon: Icons.check_circle_rounded,
                      color: _correctColor,
                    ),

                    const SizedBox(width: 10),

                    _resultBox(
                      title: 'Wrong',
                      value: '${data['wrong'] ?? 0}',
                      icon: Icons.cancel_rounded,
                      color: _wrongColor,
                    ),

                    const SizedBox(width: 10),

                    _resultBox(
                      title: 'Skipped',
                      value: '${data['skipped'] ?? 0}',
                      icon: Icons.fast_forward_rounded,
                      color: const Color(0xFFFFA726),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'Back to Levels',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _resultBox({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),

            const SizedBox(height: 5),

            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),

            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
