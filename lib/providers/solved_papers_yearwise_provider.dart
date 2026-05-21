import 'dart:io';
import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../utils/file_utils.dart';

class SolvedPaperSetProvider with ChangeNotifier {
  final StudentService _service = StudentService();
  List<dynamic> _paperSets = [];
  bool _isLoading = true;

  // Track loading per URL for localized UI spinners
  final Map<String, bool> _downloadingStatus = {};

  List<dynamic> get paperSets => _paperSets;
  bool get isLoading => _isLoading;
  bool isDownloading(String url) => _downloadingStatus[url] ?? false;

  /// UI helper to check if the "Download" icon should be hidden
  Future<bool> isPaperDownloaded(String url) async {
    final file = await FileUtils.getValidCache(url);
    return file != null;
  }

  /// 🔹 CLEANED: Uses the centralized utility
  Future<File?> downloadPaper(String url) async {
    if (url.isEmpty) return null;

    _downloadingStatus[url] = true;
    notifyListeners();

    try {
      // The utility handles the 2-day logic and the actual download
      return await FileUtils.downloadFile(url);
    } finally {
      _downloadingStatus[url] = false;
      notifyListeners();
    }
  }

  Future<void> fetchSets(String subjectId, String year) async {
    _isLoading = true;
    notifyListeners();
    try {
      _paperSets = await _service.fetchPaperSets(subjectId, year) ?? [];
    } catch (e) {
      _paperSets = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}