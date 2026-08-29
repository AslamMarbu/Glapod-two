import 'dart:math';

import 'package:flutter/material.dart';

import '../models/spelling_quiz_model.dart';
import '../services/game_zone_service.dart';

class SpellingQuizProvider extends ChangeNotifier {
  final GameZoneService _service = GameZoneService();

  List<SpellingQuizModel> quizzes = [];

  bool isLoading = false;
  bool answered = false;

  int currentQuestion = 0;
  int selectedIndex = -1;
  int score = 0;

  List<String> currentOptions = [];

  Future<void> loadQuiz(String level) async {
  isLoading = true;
  notifyListeners();

  quizzes = await _service.getSpellingQuiz(level);

  if (quizzes.isNotEmpty) {
    _shuffleOptions();
  }

  isLoading = false;
  notifyListeners();
}

  void _shuffleOptions() {
    currentOptions = [
      quizzes[currentQuestion].option1,
      quizzes[currentQuestion].option2,
      quizzes[currentQuestion].option3,
      quizzes[currentQuestion].option4,
    ];

    currentOptions.shuffle(Random());

    answered = false;
    selectedIndex = -1;
  }

  bool isCorrect(int index) {
    return currentOptions[index] ==
        quizzes[currentQuestion].correctAnswer;
  }

  void checkAnswer(int index) {
    if (answered) return;

    answered = true;
    selectedIndex = index;

    if (isCorrect(index)) {
      score += 10;
    }

    notifyListeners();
  }

  bool nextQuestion() {
    if (currentQuestion < quizzes.length - 1) {
      currentQuestion++;
      _shuffleOptions();
      notifyListeners();
      return true;
    }

    return false;
  }

  void restart() {
    currentQuestion = 0;
    score = 0;
    _shuffleOptions();
    notifyListeners();
  }
}