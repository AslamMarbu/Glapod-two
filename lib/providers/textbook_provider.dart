import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/file_utils.dart';

class TextbookProvider extends ChangeNotifier {
  final Set<String> _downloadedUrls = {};
  final Map<String, bool> _loadingStatus = {}; // 🔹 Track loading per URL

  bool isDownloaded(String url) => _downloadedUrls.contains(url);
  bool isLoading(String url) => _loadingStatus[url] ?? false;

  /// Checks the local disk to see if the file is already there
  Future<void> checkExistingStatus(String url) async {
    if (url.isEmpty || _downloadedUrls.contains(url)) return;
    if (await FileUtils.fileExists(url)) {
      _downloadedUrls.add(url);
      notifyListeners();
    }
  }

  /// 🔹 Standardized logic: Handles downloading or retrieving path via FileUtils
  Future<File?> downloadBook(String url) async {
    if (url.isEmpty) return null;

    _loadingStatus[url] = true;
    notifyListeners();

    try {
      // FileUtils checks disk -> downloads if missing -> returns path
      final String localPath = await FileUtils.downloadAndSave(url);
      _downloadedUrls.add(url);
      return File(localPath);
    } catch (e) {
      debugPrint("Textbook Download Error: $e");
      return null;
    } finally {
      _loadingStatus[url] = false;
      notifyListeners();
    }
  }
}