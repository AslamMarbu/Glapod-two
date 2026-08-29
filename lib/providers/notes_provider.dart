import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/student_service.dart';
import '../utils/file_utils.dart';

class NotesProvider with ChangeNotifier {
  List<Map<String, dynamic>> _notes = [];

  bool _isFetchingList = true;

  final Map<String, bool> _loadingStatus = {};

  List<Map<String, dynamic>> get notes => _notes;

  bool get isFetchingList => _isFetchingList;

  bool isLoading(String url) => _loadingStatus[url] ?? false;

  Future<bool> isNoteValid(String url) async {
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
        debugPrint('Notes download failed => $url');
      }

      return file;
    } catch (e) {
      debugPrint('Notes download error => $e');
      return null;
    } finally {
      _loadingStatus[url] = false;
      notifyListeners();
    }
  }

  Future<void> fetchNotes(dynamic chapterId) async {
    _isFetchingList = true;
    _notes = [];
    notifyListeners();

    try {
      final List<dynamic> rawData = await StudentService.fetchNotes(chapterId);

      final String bridge = jsonEncode(rawData);
      final List<dynamic> cleanData = jsonDecode(bridge);

      _notes = cleanData
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } catch (e) {
      _notes = [];
      debugPrint('Notes Provider Error => $e');
    } finally {
      _isFetchingList = false;
      notifyListeners();
    }
  }
}
