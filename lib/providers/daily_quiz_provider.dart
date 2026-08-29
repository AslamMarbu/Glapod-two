import 'dart:async';

import 'package:flutter/material.dart';

import '../models/daily_quiz_model.dart';
import '../services/daily_quiz_service.dart';

class DailyQuizProvider extends ChangeNotifier {
  final DailyQuizService _service = DailyQuizService();

  /// ================================
  /// QUIZ DATA
  /// ================================

  List<DailyQuizModel> quizzes = [];

  List<DailyQuizAnswer> answers = [];

  bool isLoading = false;
  bool isSubmitting = false;
  bool quizCompleted = false;

  String? errorMessage;

  /// ================================
  /// QUESTION STATE
  /// ================================

  int currentQuestion = 0;

  String? selectedAnswer;

  bool answered = false;

  /// ================================
  /// SCORE
  /// ================================

  int score = 0;

  int correct = 0;

  int wrong = 0;

  int skipped = 0;

  /// ================================
  /// TIMERS
  /// ================================

  Timer? _quizTimer;

  Timer? _questionTimer;

  int totalTime = 300;

  int questionTime = 15;

  /// ================================
  /// GETTERS
  /// ================================

  bool get hasQuestions => quizzes.isNotEmpty;

  bool get isLastQuestion =>
      currentQuestion == quizzes.length - 1;

  double get progress =>
      quizzes.isEmpty
          ? 0
          : (currentQuestion + 1) / quizzes.length;

  DailyQuizModel get currentQuiz =>
      quizzes[currentQuestion];

  /// ================================
  /// LOAD QUIZ
  /// ================================

  Future<void> loadQuiz() async {
    try {
      isLoading = true;
      errorMessage = null;

      notifyListeners();

      quizzes = await _service.getDailyQuiz();

      answers.clear();

      currentQuestion = 0;

      selectedAnswer = null;

      answered = false;

      score = 0;

      correct = 0;

      wrong = 0;

      skipped = 0;

      startQuizTimer();

      startQuestionTimer();
    } catch (e) {
      errorMessage = e.toString();
    }

    isLoading = false;

    notifyListeners();
  }

  /// ================================
  /// SELECT ANSWER
  /// ================================

  void selectAnswer(String answer) {
    if (answered) return;

    answered = true;

    selectedAnswer = answer;

    answers.removeWhere(
      (element) =>
          element.questionId ==
          currentQuiz.id,
    );

    answers.add(
      DailyQuizAnswer(
        questionId: currentQuiz.id,
        selectedAnswer: answer,
      ),
    );

    _questionTimer?.cancel();

    notifyListeners();
  }

  /// ================================
  /// QUESTION TIMER
  /// ================================

  void startQuestionTimer() {
    _questionTimer?.cancel();

    questionTime = 15;

    _questionTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (questionTime > 0) {
          questionTime--;

          notifyListeners();
        } else {
          timer.cancel();

          skipped++;

          nextQuestion();
        }
      },
    );
  }

  /// ================================
  /// QUIZ TIMER
  /// ================================

  void startQuizTimer() {
    _quizTimer?.cancel();

    totalTime = 300;

    _quizTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (totalTime > 0) {
          totalTime--;

          notifyListeners();
        } else {
          timer.cancel();

          submitQuiz();
        }
      },
    );
  }
    /// ================================
  /// NEXT QUESTION
  /// ================================

  Future<void> nextQuestion() async {
    _questionTimer?.cancel();

    if (currentQuestion < quizzes.length - 1) {
      currentQuestion++;

      selectedAnswer = null;

      answered = false;

      startQuestionTimer();

      notifyListeners();

      return;
    }

    await submitQuiz();
  }

  /// ================================
  /// SUBMIT QUIZ
  /// ================================

  Future<void> submitQuiz() async {
    if (quizCompleted) return;

    quizCompleted = true;

    _quizTimer?.cancel();
    _questionTimer?.cancel();

    isSubmitting = true;

    notifyListeners();

    try {
      final result = await _service.submitDailyQuiz(
        answers: answers,
      );

      score = result['score'] ?? 0;
      correct = result['correct'] ?? 0;
      wrong = result['wrong'] ?? 0;
      skipped = result['skipped'] ?? skipped;
    } catch (e) {
      errorMessage = e.toString();
    }

    isSubmitting = false;

    notifyListeners();
  }

  /// ================================
  /// RESTART QUIZ
  /// ================================

  Future<void> restartQuiz() async {
    _quizTimer?.cancel();
    _questionTimer?.cancel();

    quizzes.clear();
    answers.clear();

    currentQuestion = 0;

    score = 0;
    correct = 0;
    wrong = 0;
    skipped = 0;

    selectedAnswer = null;

    answered = false;

    totalTime = 300;
    questionTime = 15;

    quizCompleted = false;
    errorMessage = null;

    notifyListeners();

    await loadQuiz();
  }

  /// ================================
  /// TIME FORMATTERS
  /// ================================

  String get totalTimerText {
    final minutes = totalTime ~/ 60;
    final seconds = totalTime % 60;

    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  String get questionTimerText {
    return questionTime.toString();
  }

  /// ================================
  /// OPTION HELPERS
  /// ================================

  List<String> get options {
    if (quizzes.isEmpty) return [];

    return [
      currentQuiz.optionA,
      currentQuiz.optionB,
      currentQuiz.optionC,
      currentQuiz.optionD,
    ];
  }

  bool isSelected(String option) {
    return selectedAnswer == option;
  }

  bool get canGoNext {
    return answered || questionTime == 0;
  }

  /// ================================
  /// DISPOSE
  /// ================================

  @override
  void dispose() {
    _quizTimer?.cancel();
    _questionTimer?.cancel();

    super.dispose();
  }
}