import 'package:flutter/material.dart';
import '../services/student_service.dart';

class PredictionProvider with ChangeNotifier {
  List<dynamic> _categories = [];
  bool _isLoading = true;

  List<dynamic> get categories => _categories;
  bool get isLoading => _isLoading;

  // Centralized Level Labels
  final List<String> displayLabels = ["Beginner", "Intermediate", "Advanced"];

  /// Maps UI labels to API keys
  String mapToApi(String displayLabel) {
    const mapping = {
      "Beginner": "beginner",
      "Intermediate": "intermediate",
      "Advanced": "advanced",
    };
    return mapping[displayLabel] ?? "beginner";
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();
    try {
      _categories = await StudentService.fetchGuessNameCategories();
    } catch (e) {
      _categories = [];
      debugPrint("PredictionProvider Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}