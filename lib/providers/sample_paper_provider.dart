import 'dart:io';
import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../utils/file_utils.dart';

class SamplePaperProvider with ChangeNotifier {
  List<dynamic> _papers = [];
  bool _isLoading = false;

  // 🔹 Use URL or ID as a key to track loading spinners in the UI
  final Map<String, bool> _downloadingStatus = {};

  List<dynamic> get papers => _papers;
  bool get isLoading => _isLoading;

  /// Helper to check if a specific item is currently downloading
  bool isDownloading(String id) => _downloadingStatus[id] ?? false;

  // 🔹 Helper to extract the correct URL consistently
  String _getPdfUrl(dynamic paper) {
    return (paper['file'] ?? paper['file_url'] ?? paper['paper_url'] ?? "").toString();
  }

  /// 🔹 Standardized: Checks cache validity via FileUtils
  Future<bool> isPaperDownloaded(String url) async {
    if (url.isEmpty) return false;
    final file = await FileUtils.getValidCache(url);
    return file != null;
  }

  Future<void> fetchPapers(String classId, String subjectId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _papers = await StudentService.fetchSamplePapers(classId, subjectId);
    } catch (e) {
      _papers = [];
      debugPrint("Fetch Papers Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔹 Updated: Uses centralized FileUtils logic
  Future<File?> downloadPaper(dynamic paper) async {
    final String url = _getPdfUrl(paper);
    final String id = paper['id'].toString();

    if (url.isEmpty || url == "null") return null;

    _downloadingStatus[id] = true;
    notifyListeners();

    try {
      // 🔹 Centralized logic handles hashing, 2-day expiry, and download
      return await FileUtils.downloadFile(url);
    } catch (e) {
      debugPrint("Download Error: $e");
      return null;
    } finally {
      _downloadingStatus[id] = false;
      notifyListeners();
    }
  }
}