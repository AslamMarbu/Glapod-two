import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/student_service.dart';
import '../utils/file_utils.dart';

class MedMasterProvider with ChangeNotifier {
  List<Map<String, dynamic>> _medMasterList = [];

  bool _isFetchingList = true;

  final Map<String, bool> _loadingStatus = {};

  List<Map<String, dynamic>> get medMasterList => _medMasterList;

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
        debugPrint('Med Master download failed => $url');
      }

      return file;
    } catch (e) {
      debugPrint('Med Master download error => $e');
      return null;
    } finally {
      _loadingStatus[url] = false;
      notifyListeners();
    }
  }

  Future<void> fetchMedMasterPdfs() async {
    _isFetchingList = true;
    _medMasterList = [];
    notifyListeners();

    try {
      final List<dynamic> rawData = await StudentService.fetchMedMasterPdfs();

      final String bridge = jsonEncode(rawData);
      final List<dynamic> cleanData = jsonDecode(bridge);

      _medMasterList = cleanData
          .map((category) => Map<String, dynamic>.from(category))
          .toList();
    } catch (e) {
      _medMasterList = [];
      debugPrint('Med Master error => $e');
    } finally {
      _isFetchingList = false;
      notifyListeners();
    }
  }
}
