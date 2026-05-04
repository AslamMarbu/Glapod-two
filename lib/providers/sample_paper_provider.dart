import 'dart:io';
import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../utils/file_utils.dart'; // Ensure FileUtils is imported

class SamplePaperProvider with ChangeNotifier {
  List<dynamic> _papers = [];
  bool _isLoading = false;

  // 🔹 Track downloading status for each paper by its ID
  final Map<String, bool> _downloadingStatus = {};

  List<dynamic> get papers => _papers;
  bool get isLoading => _isLoading;
  Map<String, bool> get downloadingStatus => _downloadingStatus;

  Future<void> fetchPapers(String classId, String subjectId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _papers = await StudentService.fetchSamplePapers(classId, subjectId);
    } catch (e) {
      debugPrint("Error fetching papers: $e");
      _papers = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔹 Centralized logic: Handles downloading and returns local file path
  Future<File?> downloadPaper(dynamic paper) async {
    final String url = paper['file'] ?? paper['paper_url'] ?? "";
    final String id = paper['id'].toString();

    if (url.isEmpty) return null;

    // Start loading for this specific ID
    _downloadingStatus[id] = true;
    notifyListeners();

    try {
      // FileUtils handles logic: check disk -> download if missing -> return path
      final String localPath = await FileUtils.downloadAndSave(url);
      return File(localPath);
    } catch (e) {
      debugPrint("Paper Download Error: $e");
      return null;
    } finally {
      // Stop loading
      _downloadingStatus[id] = false;
      notifyListeners();
    }
  }
}