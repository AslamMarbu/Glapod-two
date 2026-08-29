import 'dart:io';

import 'package:flutter/material.dart';

import '../services/student_service.dart';
import '../utils/file_utils.dart';

class YearwiseQPaperProvider with ChangeNotifier {
  final StudentService _service = StudentService();

  List<dynamic> _paperSets = [];
  bool _isLoading = true;
  bool _isPrefetching = false;

  final Map<String, bool> _downloadingStatus = {};

  List<dynamic> get paperSets => _paperSets;

  bool get isLoading => _isLoading;

  bool isDownloading(String url) => _downloadingStatus[url] ?? false;

  Future<bool> isPaperDownloaded(String url) async {
    if (url.isEmpty || url == "null") {
      return false;
    }

    final file = await FileUtils.getValidCache(url);

    return file != null;
  }

  Future<void> fetchSets(String subjectId, String year) async {
    _isLoading = true;
    _paperSets = [];
    notifyListeners();

    try {
      final result = await _service.fetchPaperSets(subjectId, year);

      _paperSets = result ?? [];

      await prefetchPaperFiles();
    } catch (e) {
      debugPrint("Error fetching paper sets: $e");

      _paperSets = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<File?> downloadPaper(String url) async {
    if (url.isEmpty || url == "null") {
      return null;
    }

    if (_downloadingStatus[url] == true) {
      return null;
    }

    _downloadingStatus[url] = true;
    notifyListeners();

    try {
      final file = await FileUtils.downloadFile(url);

      if (file == null) {
        debugPrint("Paper download failed => $url");
      }

      return file;
    } catch (e) {
      debugPrint("Paper download error => $e");

      return null;
    } finally {
      _downloadingStatus[url] = false;
      notifyListeners();
    }
  }

  Future<void> prefetchPaperFiles() async {
    if (_isPrefetching) {
      return;
    }

    _isPrefetching = true;

    try {
      for (final paper in _paperSets) {
        if (paper is! Map) {
          continue;
        }

        final String url = (paper['pdf'] ?? paper['file'] ?? paper['url'] ?? '')
            .toString();

        if (url.isEmpty || url == 'null') {
          continue;
        }

        final bool alreadyCached = await isPaperDownloaded(url);

        if (!alreadyCached) {
          debugPrint("Paper cache missing/expired => $url");

          await downloadPaper(url);
        }
      }
    } catch (e) {
      debugPrint("Paper prefetch error => $e");
    } finally {
      _isPrefetching = false;
    }
  }
}
