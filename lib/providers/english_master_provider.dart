import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/student_service.dart';
import '../utils/file_utils.dart';

class EnglishMasterProvider with ChangeNotifier {
  List<Map<String, dynamic>> _englishMasterList = [];
  bool _isFetchingList = true;
  final Map<String, bool> _loadingStatus = {};
  final Map<String, Future<File?>> _activeDownloads = {};

  List<Map<String, dynamic>> get englishMasterList => _englishMasterList;
  bool get isFetchingList => _isFetchingList;
  bool isLoading(String url) => _loadingStatus[url] ?? false;

  Future<bool> isPdfValid(String url) async {
    if (_isInvalidUrl(url)) return false;
    return (await FileUtils.getValidCache(url)) != null;
  }

  Future<File?> downloadFile(String url) async {
    final cleanUrl = url.trim();
    if (_isInvalidUrl(cleanUrl)) return null;
    final active = _activeDownloads[cleanUrl];
    if (active != null) return active;

    _loadingStatus[cleanUrl] = true;
    notifyListeners();
    final future = _downloadInternal(cleanUrl);
    _activeDownloads[cleanUrl] = future;

    try {
      return await future;
    } finally {
      _activeDownloads.remove(cleanUrl);
      _loadingStatus[cleanUrl] = false;
      notifyListeners();
    }
  }

  Future<File?> _downloadInternal(String url) async {
    try {
      final file = await FileUtils.downloadFile(url);
      if (file == null) debugPrint('English Master download failed => $url');
      return file;
    } catch (e) {
      debugPrint('English Master download error => $e');
      return null;
    }
  }

  Future<void> fetchEnglishMasterCategories() async {
    _isFetchingList = true;
    _englishMasterList = [];
    notifyListeners();

    try {
      final List<dynamic> rawData =
          await StudentService.fetchEnglishMasterCategories();

      final List<dynamic> cleanData = jsonDecode(jsonEncode(rawData));

      _englishMasterList = cleanData.map((item) {
        final category = Map<String, dynamic>.from(item);

        return {
          'id': category['id'],
          'name': category['name'] ?? '',
          'image': category['image'] ?? '',
          'single_file': category['single_file'],
          'files': category['files'] ?? [],
        };
      }).toList();
    } catch (e) {
      _englishMasterList = [];
      debugPrint('English Master error => $e');
    } finally {
      _isFetchingList = false;
      notifyListeners();
    }
  }

  bool _isInvalidUrl(String url) =>
      url.trim().isEmpty || url.trim().toLowerCase() == 'null';
}
