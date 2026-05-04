import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../models/question_year_model.dart';

class QuestionProvider with ChangeNotifier {
  final StudentService _service = StudentService();
  List<YearSetData> _years = [];
  bool _isLoading = false;

  List<YearSetData> get years => _years;
  bool get isLoading => _isLoading;

  Future<void> fetchYears(String subjectId) async {
    _isLoading = true;
    _years = []; // Clear old data while loading new subject
    notifyListeners();

    try {
      final result = await _service.fetchYears(int.parse(subjectId));
      if (result != null) {
        _years = result.years;
      }
    } catch (e) {
      debugPrint("Error loading years in Provider: $e");
      _years = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}