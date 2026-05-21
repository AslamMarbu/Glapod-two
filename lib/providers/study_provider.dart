import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../storage/local_storage_service.dart';

class StudyProvider with ChangeNotifier {
  List<dynamic> _subjects = [];
  bool _isLoading = false;
  String _savedClassId = '';

  // Getters
  List<dynamic> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String get savedClassId => _savedClassId;

  Future<void> loadSubjects() async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Fetch Class ID from Local Storage
      final studentData = await LocalStorageService.getStudent();
      _savedClassId = studentData?['class_id']?.toString() ?? "3";

      // 2. Fetch data from the API
      // (The Dio Interceptor will handle the cache behind the scenes)
      final List<dynamic> freshData = await StudentService.fetchSubjects(_savedClassId);

      _subjects = freshData;
    } catch (e) {
      debugPrint("Error in loadSubjects: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}