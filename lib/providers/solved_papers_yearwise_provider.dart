import 'dart:io';

import 'package:flutter/material.dart';

import '../services/student_service.dart';
import '../utils/file_utils.dart';

class SolvedPaperSetProvider with ChangeNotifier {
  final StudentService _service = StudentService();

  List<dynamic> _paperSets = [];

  bool _isLoading = true;

  final Map<String, bool> _downloadingStatus = {};

  List<dynamic> get paperSets => _paperSets;

  bool get isLoading => _isLoading;

  bool isDownloading(String url) => _downloadingStatus[url] ?? false;

  Future<bool> isPaperDownloaded(String url) async {
    if (url.isEmpty || url == 'null') {
      return false;
    }

    final file = await FileUtils.getValidCache(url);

    return file != null;
  }

  Future<File?> downloadPaper(String url) async {
    if (url.isEmpty || url == 'null') {
      return null;
    }

    _downloadingStatus[url] = true;
    notifyListeners();

    try {
      final file = await FileUtils.downloadFile(url);

      if (file == null) {
        debugPrint('Solved paper download failed => $url');
      }

      return file;
    } catch (e) {
      debugPrint('Solved paper download error => $e');

      return null;
    } finally {
      _downloadingStatus[url] = false;
      notifyListeners();
    }
  }

  Future<void> fetchSets(String subjectId, String year) async {
    _isLoading = true;
    _paperSets = [];
    notifyListeners();

    try {
      _paperSets = await _service.fetchPaperSets(subjectId, year) ?? [];
    } catch (e) {
      debugPrint('Error fetching solved paper sets => $e');

      _paperSets = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
