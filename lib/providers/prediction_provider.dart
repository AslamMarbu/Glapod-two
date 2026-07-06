import 'package:flutter/material.dart';
import '../services/student_service.dart';

class PredictionProvider with ChangeNotifier {
  // Keep it as dynamic, but initialize as an empty growable list to prevent type errors
  List<dynamic> _categories = [];
  bool _isLoading = true;

  List<dynamic> get categories => _categories;
  bool get isLoading => _isLoading;

  final List<String> displayLabels = ["Beginner", "Intermediate", "Advanced"];

  /// Maps UI labels to API keys (Simplified using .toLowerCase())
  String mapToApi(String displayLabel) {
    return displayLabel.toLowerCase();
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Basic fix: Use List.from() to ensure Dart safely casts whatever the service returns
      final data = await StudentService.fetchGuessNameCategories();
      _categories = List<dynamic>.from(data ?? []);
    } catch (e) {
      _categories = [];
      debugPrint("PredictionProvider Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
