import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/daily_quiz_provider.dart';

class DailyQuizGamePage extends StatefulWidget {
  const DailyQuizGamePage({super.key});

  @override
  State<DailyQuizGamePage> createState() => _DailyQuizGamePageState();
}

class _DailyQuizGamePageState extends State<DailyQuizGamePage> {
  static const Color _purple = Color(0xFF5B2EFF);
  static const Color _deepPurple = Color(0xFF3D1AA3);
  static const Color _orange = Color(0xFFFF9800);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<DailyQuizProvider>();
      if (provider.quizCompleted) {
        provider.restartQuiz();
      } else {
        provider.loadQuiz();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DailyQuizProvider>(
      builder: (context, provider, child) {
        return PopScope(
          canPop: provider.quizCompleted || !provider.hasQuestions,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop || provider.quizCompleted || !provider.hasQuestions) {
              return;
            }

            final shouldExit = await _showExitDialog(context);
            if (shouldExit == true && context.mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFF7F8FC),
            body: _buildBody(provider),
          ),
        );
      },
    );
  }

  Widget _buildBody(DailyQuizProvider provider) {
    if (provider.isLoading) {
      return _buildLoadingState();
    }

    if (provider.errorMessage != null && !provider.hasQuestions) {
      return _buildErrorState(provider);
    }

    if (!provider.hasQuestions) {
      return _buildEmptyState(provider);
    }

    if (provider.quizCompleted) {
      return _buildResultScreen(provider);
    }

    return _buildQuizScreen(provider);
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF0EAFF), Color(0xFFF9FAFD)],
        ),
      ),
      child: const SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _purple),
              SizedBox(height: 18),
              Text(
                'Preparing your daily quiz...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4E466B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(DailyQuizProvider provider) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 44,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Unable to load quiz',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF201A35),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _cleanError(provider.errorMessage),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  height: 1.5,
                  fontSize: 15,
                  color: Color(0xFF716B80),
                ),
              ),
              const SizedBox(height: 26),
              _primaryButton(
                label: 'Try Again',
                icon: Icons.refresh_rounded,
                onPressed: provider.loadQuiz,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(DailyQuizProvider provider) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.quiz_outlined, size: 76, color: _purple),
              const SizedBox(height: 18),
              const Text(
                'No quiz available today',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF201A35),
                ),
              ),
              const SizedBox(height: 24),
              _primaryButton(
                label: 'Refresh',
                icon: Icons.refresh_rounded,
                onPressed: provider.loadQuiz,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuizScreen(DailyQuizProvider provider) {
    final quiz = provider.currentQuiz;
    final options = provider.options;
    final int questionNumber = provider.currentQuestion + 1;
    final int totalQuestions = provider.quizzes.length;
    final int percentage = (provider.progress * 100).round();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEDE6FF), Color(0xFFF8F9FC)],
          stops: [0.0, 0.36],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildTopBar(provider),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressCard(
                      questionNumber: questionNumber,
                      totalQuestions: totalQuestions,
                      percentage: percentage,
                      progress: provider.progress,
                    ),
                    const SizedBox(height: 18),
                    _buildQuestionCard(
                      questionNumber: questionNumber,
                      question: quiz.question,
                      questionTime: provider.questionTime,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Choose the correct answer',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF615A70),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(
                      options.length,
                      (index) => _buildOptionCard(
                        provider: provider,
                        option: options[index],
                        index: index,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildNextButton(provider),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(DailyQuizProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () async {
              final shouldExit = await _showExitDialog(context);
              if (shouldExit == true && mounted) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            color: const Color(0xFF241B3A),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Quiz',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF241B3A),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Test your knowledge',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF766E89),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, size: 19, color: _orange),
                const SizedBox(width: 6),
                Text(
                  provider.totalTimerText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2A2338),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required int questionNumber,
    required int totalQuestions,
    required int percentage,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question $questionNumber of $totalQuestions',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF332B46),
                ),
              ),
              Text(
                '$percentage%',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: _purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFE9E5F2),
              valueColor: const AlwaysStoppedAnimation<Color>(_purple),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard({
    required int questionNumber,
    required String question,
    required int questionTime,
  }) {
    final bool isUrgent = questionTime <= 5;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'QUESTION $questionNumber',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                    color: _purple,
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isUrgent
                      ? Colors.red.withOpacity(0.10)
                      : _orange.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isUrgent ? Colors.redAccent : _orange,
                    width: 2,
                  ),
                ),
                child: Text(
                  '$questionTime',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isUrgent ? Colors.redAccent : _orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: _purple.withOpacity(0.09),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: _purple,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    fontSize: 20,
                    height: 1.38,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F1A2E),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required DailyQuizProvider provider,
    required String option,
    required int index,
  }) {
    final bool selected = provider.isSelected(option);
    final String label = String.fromCharCode(65 + index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: provider.answered ? null : () => provider.selectAnswer(option),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
              color: selected ? _purple.withOpacity(0.08) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? _purple : const Color(0xFFE8E5EE),
                width: selected ? 2 : 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.025),
                  blurRadius: 9,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? _purple : const Color(0xFFF0EDFA),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: selected ? Colors.white : _deepPurple,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                      color: selected ? _deepPurple : const Color(0xFF302A3E),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: selected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          key: ValueKey('selected'),
                          color: _purple,
                        )
                      : const SizedBox(
                          key: ValueKey('not-selected'),
                          width: 24,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextButton(DailyQuizProvider provider) {
    final bool enabled = provider.answered && !provider.isSubmitting;
    final String label = provider.isLastQuestion
        ? 'Finish Quiz'
        : 'Next Question';

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: enabled
              ? const LinearGradient(
                  colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                )
              : null,
          color: enabled ? null : const Color(0xFFE0DEE5),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: _orange.withOpacity(0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: enabled ? provider.nextQuestion : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: provider.isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: enabled ? Colors.white : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      provider.isLastQuestion
                          ? Icons.flag_rounded
                          : Icons.arrow_forward_rounded,
                      color: enabled ? Colors.white : Colors.grey.shade500,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildResultScreen(DailyQuizProvider provider) {
    if (provider.isSubmitting) {
      return const SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _purple),
              SizedBox(height: 18),
              Text(
                'Calculating your result...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4E466B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final int total = provider.quizzes.length;
    final double accuracy = total == 0 ? 0 : provider.correct / total;
    final int percentage = (accuracy * 100).round();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFECE5FF), Color(0xFFF8F9FD)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 30),
          child: Column(
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _purple.withOpacity(0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 58,
                  color: _orange,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Quiz Completed!',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF211A35),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _resultMessage(percentage),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: Color(0xFF726B81),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'YOUR SCORE',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                        color: Color(0xFF817990),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${provider.score}',
                      style: const TextStyle(
                        fontSize: 54,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: _purple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$percentage% accuracy',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF655E74),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: accuracy.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: const Color(0xFFEAE7F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          _purple,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _resultTile(
                      title: 'Correct',
                      value: provider.correct,
                      icon: Icons.check_circle_rounded,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _resultTile(
                      title: 'Wrong',
                      value: provider.wrong,
                      icon: Icons.cancel_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _resultTile(
                      title: 'Skipped',
                      value: provider.skipped,
                      icon: Icons.skip_next_rounded,
                      color: _orange,
                    ),
                  ),
                ],
              ),
              if (provider.errorMessage != null) ...[
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _cleanError(provider.errorMessage),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _primaryButton(
                label: 'Play Again',
                icon: Icons.replay_rounded,
                onPressed: provider.restartQuiz,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Back to Fun Master'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _deepPurple,
                    side: const BorderSide(color: _purple, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultTile({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 27),
          const SizedBox(height: 7),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: Color(0xFF272133),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7C7588),
            ),
          ),
        ],
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          gradient: const LinearGradient(colors: [_purple, _deepPurple]),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.27),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Leave the quiz?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Your current quiz progress will be lost.',
            style: TextStyle(height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Continue Quiz'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
  }

  String _cleanError(String? error) {
    if (error == null || error.trim().isEmpty) {
      return 'Something went wrong. Please try again.';
    }

    return error.replaceFirst('Exception: ', '').trim();
  }

  String _resultMessage(int percentage) {
    if (percentage >= 80) {
      return 'Excellent work! You have a strong understanding of today’s questions.';
    }
    if (percentage >= 50) {
      return 'Good effort! Keep practising and your score will improve.';
    }
    return 'Nice try! Review the topic and come back stronger next time.';
  }
}
