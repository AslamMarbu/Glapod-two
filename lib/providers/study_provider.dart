import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../storage/local_storage_service.dart';

class StudyProvider with ChangeNotifier {
  List<dynamic> _subjects = [];
  bool _isLoading = true;
  String _savedClassId = '';

  // Getters
  List<dynamic> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String get savedClassId => _savedClassId;

  Future<void> loadSubjects() async {
    _isLoading = true;
    notifyListeners(); // Tell the UI to show the loading spinner

    try {
      final studentData = await LocalStorageService.getStudent();
      _savedClassId = studentData?['class_id']?.toString() ?? "3";

      _subjects = await StudentService.fetchSubjects(_savedClassId);
    } catch (e) {
      debugPrint("Error loading subjects: $e");
      _subjects = [];
    } finally {
      _isLoading = false;
      notifyListeners(); // Tell UI to rebuild with data
    }
  }
}