import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../storage/local_storage_service.dart';

class SolvedPapersProvider with ChangeNotifier {
  List<dynamic> _papers = [];
  bool _isLoading = true;
  bool _hasDataToShow = false;

  List<dynamic> get papers => _papers;
  bool get isLoading => _isLoading;
  bool get hasDataToShow => _hasDataToShow;

  Future<void> fetchSolvedPapers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final studentData = await LocalStorageService.getStudent();
      final classId = studentData?['class_id']?.toString() ?? "3";

      final result = await StudentService.fetchSolvedPapers(classId);
      _papers = result;

      // Logic check: Does any subject actually have years?
      _hasDataToShow = _papers.any((item) {
        final List years = item['years'] ?? [];
        return years.isNotEmpty;
      });
    } catch (e) {
      debugPrint("Error in SolvedPapersProvider: $e");
      _papers = [];
      _hasDataToShow = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
