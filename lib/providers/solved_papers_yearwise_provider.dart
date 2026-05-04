import 'dart:io';
import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../utils/file_utils.dart';

class SolvedPaperSetProvider with ChangeNotifier {
  final StudentService _service = StudentService();
  List<dynamic> _paperSets = [];
  bool _isLoading = true;

  final Map<String, bool> _downloadingStatus = {};
  final Set<String> _downloadedUrls = {}; // 🔹 Track downloaded files

  List<dynamic> get paperSets => _paperSets;
  bool get isLoading => _isLoading;
  Map<String, bool> get downloadingStatus => _downloadingStatus;

  // 🔹 Check if file exists to toggle icon
  bool isFileDownloaded(String url) => _downloadedUrls.contains(url);

  Future<void> fetchSets(String subjectId, String year) async {
    _isLoading = true;
    notifyListeners();
    try {
      _paperSets = await _service.fetchPaperSets(subjectId, year) ?? [];

      // 🔹 Sync download status for all fetched papers
      for (var paper in _paperSets) {
        String url = paper['file_url'] ?? "";
        if (url.isNotEmpty && await FileUtils.fileExists(url)) {
          _downloadedUrls.add(url);
        }
      }
    } catch (e) {
      _paperSets = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<File?> downloadPaper(String url) async {
    if (url.isEmpty) return null;

    _downloadingStatus[url] = true;
    notifyListeners();

    try {
      final String localPath = await FileUtils.downloadAndSave(url);
      final file = File(localPath);

      if (await file.exists()) {
        _downloadedUrls.add(url); // 🔹 Mark as downloaded
        return file;
      }
      return null;
    } catch (e) {
      return null;
    } finally {
      _downloadingStatus[url] = false;
      notifyListeners();
    }
  }
}