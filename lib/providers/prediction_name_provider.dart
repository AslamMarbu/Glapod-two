import 'package:flutter/material.dart';
import '../services/student_service.dart';

class PredictionGameProvider with ChangeNotifier {
  Map<String, dynamic>? _currentResponse;
  bool _isLoading = false;
  bool _isCompleted = false;

  // Getters
  Map<String, dynamic>? get currentResponse => _currentResponse;
  bool get isLoading => _isLoading;
  bool get isCompleted => _isCompleted;

  /// Sets a specific question directly from the Grid data
  /// This prevents an extra API call when navigating from the grid
  void setManualQuestion(dynamic questionData) {
    _isLoading = true;
    notifyListeners();

    // We wrap the raw question data into the 'currentResponse' format
    // expected by the PredictionNamePage UI
    _currentResponse = {
      "status": true,
      "question": questionData,
    };

    _isCompleted = false;
    _isLoading = false;

    // Notify listeners so PredictionNamePage updates immediately
    notifyListeners();
  }

  /// Default method to fetch the next available question
  Future<void> loadQuestion(int categoryId, String level, {String? status}) async {
    _isLoading = true;
    _isCompleted = false;
    notifyListeners();

    try {
      // Calls your existing StudentService fetch method
      final response = await StudentService.fetchGuessNameQuestion(
        categoryId,
        level,
        status: status,
      );

      _currentResponse = response;

      // Check if the level is finished
      if (response?['completed'] == true || response?['completed'] == "true") {
        _isCompleted = true;
      }
    } catch (e) {
      debugPrint("Game Provider Error: $e");
      _currentResponse = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the feedback locally within the current question data
  void updateLocalFeedback(String newFeedback) {
    if (_currentResponse != null && _currentResponse!['question'] != null) {
      // Update the local map directly
      _currentResponse!['question']['feedback'] = newFeedback;

      // Notify listeners so the UI reflects the change
      notifyListeners();
    }
  }
}