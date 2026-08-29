import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/student_service.dart';
import '../utils/file_utils.dart';

class EnglishMasterProvider with ChangeNotifier {
  List<Map<String, dynamic>> _englishMasterList = [];

  bool _isFetchingList = true;

  final Map<String, bool> _loadingStatus = {};

  List<Map<String, dynamic>> get englishMasterList => _englishMasterList;

  bool get isFetchingList => _isFetchingList;

  bool isLoading(String url) => _loadingStatus[url] ?? false;

  Future<bool> isPdfValid(String url) async {
    if (url.isEmpty || url == 'null') {
      return false;
    }

    return (await FileUtils.getValidCache(url)) != null;
  }

  Future<File?> downloadFile(String url) async {
    if (url.isEmpty || url == 'null') {
      return null;
    }

    _loadingStatus[url] = true;
    notifyListeners();

    try {
      final file = await FileUtils.downloadFile(url);

      if (file == null) {
        debugPrint('English Master download failed => $url');
      }

      return file;
    } catch (e) {
      debugPrint('English Master download error => $e');

      return null;
    } finally {
      _loadingStatus[url] = false;
      notifyListeners();
    }
  }

  Future<void> fetchEnglishMasterCategories() async {
    _isFetchingList = true;
    _englishMasterList = [];
    notifyListeners();

    try {
      final List<dynamic> rawData =
          await StudentService.fetchEnglishMasterCategories();

      final String bridge = jsonEncode(rawData);

      final List<dynamic> cleanData = jsonDecode(bridge);

      _englishMasterList = cleanData
          .map((category) => Map<String, dynamic>.from(category))
          .toList();
    } catch (e) {
      _englishMasterList = [];

      debugPrint('English Master error => $e');
    } finally {
      _isFetchingList = false;
      notifyListeners();
    }
  }
}
