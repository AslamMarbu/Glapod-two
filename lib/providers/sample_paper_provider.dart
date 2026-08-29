import 'dart:io';

import 'package:flutter/material.dart';

import '../services/student_service.dart';
import '../utils/file_utils.dart';

class SamplePaperProvider with ChangeNotifier {
  List<dynamic> _papers = [];

  bool _isLoading = false;

  final Map<String, bool> _downloadingStatus = {};

  List<dynamic> get papers => _papers;

  bool get isLoading => _isLoading;

  bool isDownloading(String id) => _downloadingStatus[id] ?? false;

  String _getPdfUrl(dynamic paper) {
    return (paper['file'] ?? paper['file_url'] ?? paper['paper_url'] ?? '')
        .toString();
  }

  Future<bool> isPaperDownloaded(String url) async {
    if (url.isEmpty || url == 'null') {
      return false;
    }

    final file = await FileUtils.getValidCache(url);

    return file != null;
  }

  Future<void> fetchPapers(String classId, String subjectId) async {
    _isLoading = true;
    _papers = [];
    notifyListeners();

    try {
      _papers = await StudentService.fetchSamplePapers(classId, subjectId);
    } catch (e) {
      _papers = [];
      debugPrint('Sample Paper fetch error => $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<File?> downloadPaper(dynamic paper) async {
    final String url = _getPdfUrl(paper);

    final String id = paper['id']?.toString() ?? url;

    if (url.isEmpty || url == 'null') {
      return null;
    }

    _downloadingStatus[id] = true;
    notifyListeners();

    try {
      final file = await FileUtils.downloadFile(url);

      if (file == null) {
        debugPrint('Sample Paper download failed => $url');
      }

      return file;
    } catch (e) {
      debugPrint('Sample Paper download error => $e');

      return null;
    } finally {
      _downloadingStatus[id] = false;
      notifyListeners();
    }
  }
}
