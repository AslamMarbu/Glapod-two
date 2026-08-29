import 'package:flutter/material.dart';

import '../models/gk_master_model.dart';
import '../services/gk_master_service.dart';

class GkProvider extends ChangeNotifier {
  final GkService _service = GkService();

  /*
  |--------------------------------------------------------------------------
  | Data
  |--------------------------------------------------------------------------
  */

  List<GkZone> zones = [];
  List<GkCategory> categories = [];
  List<GkQuestion> questions = [];

  /*
  |--------------------------------------------------------------------------
  | Selected values
  |--------------------------------------------------------------------------
  */

  GkZone? selectedZone;
  GkCategory? selectedCategory;
  String? selectedLevel;

  /*
  |--------------------------------------------------------------------------
  | Loading states
  |--------------------------------------------------------------------------
  */

  bool isLoadingZones = false;
  bool isLoadingCategories = false;
  bool isLoadingQuestions = false;
  bool isSubmitting = false;

  /*
  |--------------------------------------------------------------------------
  | Error
  |--------------------------------------------------------------------------
  */

  String? errorMessage;

  /*
  |--------------------------------------------------------------------------
  | Quiz state
  |--------------------------------------------------------------------------
  */

  int currentQuestionIndex = 0;

  final Map<int, String?> selectedAnswers = {};
  final Set<int> _answeredQuestionIds = {};
  /*
  |--------------------------------------------------------------------------
  | Current question
  |--------------------------------------------------------------------------
  */

  GkQuestion? get currentQuestion {
    if (questions.isEmpty) {
      return null;
    }

    if (currentQuestionIndex < 0 || currentQuestionIndex >= questions.length) {
      return null;
    }

    return questions[currentQuestionIndex];
  }

  /*
  |--------------------------------------------------------------------------
  | Is first question
  |--------------------------------------------------------------------------
  */

  bool get isFirstQuestion {
    return currentQuestionIndex == 0;
  }

  /*
  |--------------------------------------------------------------------------
  | Is last question
  |--------------------------------------------------------------------------
  */

  bool get isLastQuestion {
    if (questions.isEmpty) {
      return false;
    }

    return currentQuestionIndex == questions.length - 1;
  }

  bool get isCurrentQuestionAnswered {
    final question = currentQuestion;

    if (question == null) {
      return false;
    }

    return _answeredQuestionIds.contains(question.id);
  }

  bool isQuestionAnswered(int questionId) {
    return _answeredQuestionIds.contains(questionId);
  }

  /*
  |--------------------------------------------------------------------------
  | Total questions
  |--------------------------------------------------------------------------
  */

  int get totalQuestions {
    return questions.length;
  }

  /*
  |--------------------------------------------------------------------------
  | Answered count
  |--------------------------------------------------------------------------
  */

  int get answeredCount {
    return selectedAnswers.values
        .where((answer) => answer != null && answer.isNotEmpty)
        .length;
  }

  /*
  |--------------------------------------------------------------------------
  | Progress
  |--------------------------------------------------------------------------
  */

  double get progress {
    if (questions.isEmpty) {
      return 0;
    }

    return (currentQuestionIndex + 1) / questions.length;
  }

  /*
  |--------------------------------------------------------------------------
  | Current selected answer
  |--------------------------------------------------------------------------
  */

  String? get currentSelectedAnswer {
    final question = currentQuestion;

    if (question == null) {
      return null;
    }

    return selectedAnswers[question.id];
  }

  /*
  |--------------------------------------------------------------------------
  | Load zones
  |--------------------------------------------------------------------------
  */

  Future<void> loadCategories() async {
    isLoadingCategories = true;
    errorMessage = null;

    notifyListeners();

    try {
      categories = await _service.fetchCategories();
    } catch (e) {
      errorMessage = _cleanError(e);
      categories = [];
    } finally {
      isLoadingCategories = false;
      notifyListeners();
    }
  }

  Future<void> selectCategory(GkCategory category) async {
    selectedCategory = category;

    selectedZone = null;
    selectedLevel = null;

    zones = [];
    questions = [];

    selectedAnswers.clear();
    _answeredQuestionIds.clear();

    currentQuestionIndex = 0;
    errorMessage = null;

    notifyListeners();

    await loadZones();
  }

  Future<void> loadZones() async {
    if (selectedCategory == null) {
      errorMessage = 'Please select a category.';
      notifyListeners();
      return;
    }

    isLoadingZones = true;
    errorMessage = null;

    notifyListeners();

    try {
      zones = await _service.fetchZones(categoryId: selectedCategory!.id);
    } catch (e) {
      errorMessage = _cleanError(e);
      zones = [];
    } finally {
      isLoadingZones = false;
      notifyListeners();
    }
  }

  void selectZone(GkZone zone) {
    selectedZone = zone;

    selectedLevel = null;

    questions = [];

    selectedAnswers.clear();
    _answeredQuestionIds.clear();

    currentQuestionIndex = 0;
    errorMessage = null;

    notifyListeners();
  }

  void selectLevel(String level) {
    selectedLevel = level.toLowerCase();

    questions = [];

    selectedAnswers.clear();
    _answeredQuestionIds.clear();

    currentQuestionIndex = 0;

    errorMessage = null;

    notifyListeners();
  }

  /*
  |--------------------------------------------------------------------------
  | Load questions
  |--------------------------------------------------------------------------
  */

  Future<bool> loadQuestions() async {
    if (selectedZone == null) {
      errorMessage = 'Please select a zone.';
      notifyListeners();
      return false;
    }

    if (selectedCategory == null) {
      errorMessage = 'Please select a category.';
      notifyListeners();
      return false;
    }

    if (selectedLevel == null) {
      errorMessage = 'Please select a level.';
      notifyListeners();
      return false;
    }

    isLoadingQuestions = true;
    errorMessage = null;

    /*
    |--------------------------------------------------------------------------
    | Clear old quiz
    |--------------------------------------------------------------------------
    */

    questions = [];
    selectedAnswers.clear();
    _answeredQuestionIds.clear();

    currentQuestionIndex = 0;

    notifyListeners();

    try {
      questions = await _service.fetchQuestions(
        zone: selectedZone!.key.toLowerCase(),
        categoryId: selectedCategory!.id,
        level: selectedLevel!.toLowerCase(),
      );

      currentQuestionIndex = 0;

      selectedAnswers.clear();
      _answeredQuestionIds.clear();

      if (questions.isEmpty) {
        errorMessage = 'No questions found for the selected quiz.';
        return false;
      }

      return true;
    } catch (e) {
      errorMessage = _cleanError(e);

      questions = [];

      return false;
    } finally {
      isLoadingQuestions = false;
      notifyListeners();
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Select answer
  |--------------------------------------------------------------------------
  */

  void selectAnswer(String optionKey) {
    final question = currentQuestion;

    if (question == null) {
      return;
    }

    // Prevent changing the answer after it has been revealed.
    if (_answeredQuestionIds.contains(question.id)) {
      return;
    }

    selectedAnswers[question.id] = optionKey;

    _answeredQuestionIds.add(question.id);

    notifyListeners();
  }

  /*
  |--------------------------------------------------------------------------
  | Clear current answer
  |--------------------------------------------------------------------------
  */

  void clearCurrentAnswer() {
    final question = currentQuestion;

    if (question == null) {
      return;
    }

    selectedAnswers[question.id] = null;

    notifyListeners();
  }

  /*
  |--------------------------------------------------------------------------
  | Next question
  |--------------------------------------------------------------------------
  */

  void nextQuestion() {
    if (questions.isEmpty) {
      return;
    }

    if (currentQuestionIndex < questions.length - 1) {
      currentQuestionIndex++;

      notifyListeners();
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Previous question
  |--------------------------------------------------------------------------
  */

  void previousQuestion() {
    if (currentQuestionIndex > 0) {
      currentQuestionIndex--;

      notifyListeners();
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Go directly to question
  |--------------------------------------------------------------------------
  */

  void goToQuestion(int index) {
    if (index < 0 || index >= questions.length) {
      return;
    }

    currentQuestionIndex = index;

    notifyListeners();
  }

  /*
  |--------------------------------------------------------------------------
  | Submit quiz
  |--------------------------------------------------------------------------
  */

  Future<Map<String, dynamic>?> submitQuiz() async {
    if (questions.isEmpty) {
      errorMessage = 'No questions available to submit.';
      notifyListeners();
      return null;
    }

    isSubmitting = true;
    errorMessage = null;

    notifyListeners();

    try {
      /*
      |--------------------------------------------------------------------------
      | Build answers
      |--------------------------------------------------------------------------
      |
      | Laravel receives:
      |
      | {
      |   "answers": [
      |       {
      |           "question_id": 1,
      |           "selected_answer": "option_b"
      |       }
      |   ]
      | }
      |
      */

      final List<Map<String, dynamic>> answers = questions.map((question) {
        return {
          'question_id': question.id,
          'selected_answer': selectedAnswers[question.id],
        };
      }).toList();

      /*
      |--------------------------------------------------------------------------
      | Submit
      |--------------------------------------------------------------------------
      */

      final result = await _service.submitQuiz(answers: answers);

      return result;
    } catch (e) {
      errorMessage = _cleanError(e);

      return null;
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  /*
  |--------------------------------------------------------------------------
  | Back from level to category
  |--------------------------------------------------------------------------
  */

  void goBackToCategories() {
    selectedCategory = null;
    selectedZone = null;
    selectedLevel = null;

    zones = [];
    questions = [];

    selectedAnswers.clear();
    _answeredQuestionIds.clear();

    currentQuestionIndex = 0;
    errorMessage = null;

    notifyListeners();
  }

  /*
  |--------------------------------------------------------------------------
  | Back from category to zone
  |--------------------------------------------------------------------------
  */

  void goBackToZones() {
    selectedZone = null;
    selectedLevel = null;

    questions = [];

    selectedAnswers.clear();
    _answeredQuestionIds.clear();

    currentQuestionIndex = 0;
    errorMessage = null;

    notifyListeners();
  }

  /*
  |--------------------------------------------------------------------------
  | Reset quiz only
  |--------------------------------------------------------------------------
  */

  void resetQuiz() {
    questions = [];

    selectedAnswers.clear();
    _answeredQuestionIds.clear();

    currentQuestionIndex = 0;

    isLoadingQuestions = false;
    isSubmitting = false;

    errorMessage = null;

    notifyListeners();
  }

  /*
  |--------------------------------------------------------------------------
  | Reset everything
  |--------------------------------------------------------------------------
  */

  void reset() {
    categories = [];
    questions = [];

    selectedZone = null;
    selectedCategory = null;
    selectedLevel = null;

    selectedAnswers.clear();
    _answeredQuestionIds.clear();

    currentQuestionIndex = 0;

    isLoadingCategories = false;
    isLoadingQuestions = false;
    isSubmitting = false;

    errorMessage = null;

    notifyListeners();
  }

  /*
  |--------------------------------------------------------------------------
  | Restart same quiz
  |--------------------------------------------------------------------------
  */

  Future<bool> restartQuiz() async {
    selectedAnswers.clear();
    _answeredQuestionIds.clear();
    currentQuestionIndex = 0;

    notifyListeners();

    return await loadQuestions();
  }

  /*
  |--------------------------------------------------------------------------
  | Error cleaner
  |--------------------------------------------------------------------------
  */

  String _cleanError(dynamic error) {
    return error.toString().replaceFirst('Exception: ', '').trim();
  }
}
