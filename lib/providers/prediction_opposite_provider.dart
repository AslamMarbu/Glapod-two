import 'package:flutter/material.dart';
import '../services/student_service.dart';

class PredictionOppositeProvider with ChangeNotifier {
  Map<String, dynamic>? _currentResponse;
  bool _isLoading = false;
  bool _isCompleted = false;

  Map<String, dynamic>? get currentResponse => _currentResponse;
  bool get isLoading => _isLoading;
  bool get isCompleted => _isCompleted;

  Future<void> loadQuestion(String level, {String? status}) async {
    _isLoading = true;
    _isCompleted = false;
    notifyListeners();

    try {
      final response = await StudentService.fetchOppositeQuestion(level, status: status);
      _currentResponse = response;

      if (response?['completed'] == true || response?['completed'] == "true") {
        _isCompleted = true;
      }
    } catch (e) {
      debugPrint("OppositeProvider Error: $e");
      _currentResponse = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}