import 'dart:io';
import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../utils/file_utils.dart';

class YearwiseQPaperProvider with ChangeNotifier {
  final StudentService _service = StudentService();
  List<dynamic> _paperSets = [];
  bool _isLoading = true;

  // 🔹 Track loading status by URL to show individual spinners
  final Map<String, bool> _downloadingStatus = {};

  List<dynamic> get paperSets => _paperSets;
  bool get isLoading => _isLoading;

  /// 🔹 Helper for the UI to check downloading state
  bool isDownloading(String url) => _downloadingStatus[url] ?? false;

  /// 🔹 Standardized: Checks if the file is in cache and valid (< 2 days old)
  Future<bool> isPaperDownloaded(String url) async {
    if (url.isEmpty || url == "null") return false;
    final file = await FileUtils.getValidCache(url);
    return file != null;
  }

  Future<void> fetchSets(String subjectId, String year) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _service.fetchPaperSets(subjectId, year);
      _paperSets = result ?? [];
    } catch (e) {
      debugPrint("Error fetching paper sets: $e");
      _paperSets = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔹 Cleaned: Uses the centralized download logic
  Future<File?> downloadPaper(String url) async {
    if (url.isEmpty || url == "null") return null;

    _downloadingStatus[url] = true;
    notifyListeners();

    try {
      // 🔹 Centralized logic handles MD5 hashing, 2-day expiry, and download
      return await FileUtils.downloadFile(url);
    } catch (e) {
      debugPrint("Download error: $e");
      return null;
    } finally {
      _downloadingStatus[url] = false;
      notifyListeners();
    }
  }
}