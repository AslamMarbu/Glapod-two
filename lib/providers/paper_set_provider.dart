import 'package:flutter/material.dart';
import '../services/student_service.dart';

class PaperSetProvider with ChangeNotifier {
  final StudentService _service = StudentService();
  List<dynamic> _paperSets = [];
  bool _isLoading = false;

  List<dynamic> get paperSets => _paperSets;
  bool get isLoading => _isLoading;

  Future<void> fetchPaperSets(String subjectId, String year) async {
    _isLoading = true;
    _paperSets = []; // Reset list when loading a new year
    notifyListeners();

    try {
      final result = await _service.fetchPaperSets(subjectId, year);
      _paperSets = result ?? [];
    } catch (e) {
      debugPrint("Error fetching paper sets in Provider: $e");
      _paperSets = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}