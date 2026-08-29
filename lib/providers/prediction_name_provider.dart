import 'package:flutter/material.dart';
import '../services/student_service.dart';

class PredictionGameProvider with ChangeNotifier {
  Map<String, dynamic>? _currentResponse;

  bool _isLoading = false;
  bool _isCompleted = false;
  bool _hasNoData = false;

  // Getters
  Map<String, dynamic>? get currentResponse => _currentResponse;

  bool get isLoading => _isLoading;

  bool get isCompleted => _isCompleted;

  bool get hasNoData => _hasNoData;

  /// Sets a specific question directly from the Grid data.
  /// This prevents an extra API call when navigating from the grid.
  void setManualQuestion(dynamic questionData) {
    _isLoading = true;
    _hasNoData = false;
    notifyListeners();

    // If the grid somehow sends null/empty data,
    // treat it as no question available.
    if (questionData == null) {
      _currentResponse = null;
      _isCompleted = false;
      _hasNoData = true;
      _isLoading = false;
      notifyListeners();
      return;
    }

    _currentResponse = {"status": true, "question": questionData};

    _isCompleted = false;
    _hasNoData = false;
    _isLoading = false;

    notifyListeners();
  }

  /// Fetch question from server.
  Future<void> loadQuestion(
    int categoryId,
    String level, {
    String? status,
  }) async {
    _isLoading = true;
    _isCompleted = false;
    _hasNoData = false;
    _currentResponse = null;

    notifyListeners();

    try {
      final response = await StudentService.fetchGuessNameQuestion(
        categoryId,
        level,
        status: status,
      );

      _currentResponse = response;

      // ---------------------------------------------------------
      // 1. QUIZ COMPLETED
      // This is NOT "No Questions"
      // ---------------------------------------------------------
      if (response['completed'] == true ||
          response['completed'].toString() == 'true') {
        _isCompleted = true;
        _hasNoData = false;
        return;
      }

      // ---------------------------------------------------------
      // 2. ACTUAL CATEGORY HAS NO QUESTIONS
      // ---------------------------------------------------------
      final String message = (response['message'] ?? '')
          .toString()
          .toLowerCase();

      if (response['status'] == false &&
          (message.contains('questions not found') ||
              message.contains('no questions found') ||
              message.contains('no question available'))) {
        _hasNoData = true;
        _isCompleted = false;
        return;
      }

      // ---------------------------------------------------------
      // 3. VALID QUESTION
      // ---------------------------------------------------------
      if (response['status'] == true && response['question'] != null) {
        _hasNoData = false;
        _isCompleted = false;
        return;
      }

      // Unknown/API error:
      // do NOT call it "No Questions".
      _hasNoData = false;
      _isCompleted = false;
    } catch (e) {
      debugPrint("Game Provider Error: $e");

      _currentResponse = null;

      // Network/server errors are NOT no-data.
      _hasNoData = false;
      _isCompleted = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the feedback locally within the current question data.
  void updateLocalFeedback(String newFeedback) {
    if (_currentResponse != null && _currentResponse!['question'] != null) {
      _currentResponse!['question']['feedback'] = newFeedback;

      notifyListeners();
    }
  }

  /// Clear old question state when required.
  void clearQuestion() {
    _currentResponse = null;
    _isLoading = false;
    _isCompleted = false;
    _hasNoData = false;

    notifyListeners();
  }
}
