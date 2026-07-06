import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../storage/local_storage_service.dart';
import '../utils/api_cache_service.dart';

class StudyProvider with ChangeNotifier {
  List<dynamic> _subjects = [];
  bool _isLoading = false;
  String _savedClassId = '';

  List<dynamic> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String get savedClassId => _savedClassId;

  Future<void> loadSubjects() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get student data
      final studentData = await LocalStorageService.getStudent();

      debugPrint("================================");
      debugPrint("Student Data: $studentData");

      _savedClassId = studentData?['class_id']?.toString() ?? "3";

      debugPrint("Selected Class ID: $_savedClassId");

      // Clear old cached subjects
      await ApiCacheService.clearCache(
        '/api/study/get-subjects/$_savedClassId',
      );

      // Fetch fresh subjects from server
      final List<dynamic> freshData = await StudentService.fetchSubjects(
        _savedClassId,
      );

      debugPrint("Subjects Count: ${freshData.length}");

      if (freshData.isNotEmpty) {
        debugPrint("First Subject: ${freshData.first}");
      } else {
        debugPrint("No subjects returned from API");
      }

      _subjects = freshData;

      debugPrint("Stored Subjects Count: ${_subjects.length}");
      debugPrint("================================");
    } catch (e, stackTrace) {
      debugPrint("Error in loadSubjects: $e");
      debugPrint("Stack Trace: $stackTrace");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
