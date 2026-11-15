import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../services/student_service.dart';
import '../utils/file_utils.dart';

class NotesProvider with ChangeNotifier {
  List<Map<String, dynamic>> _notes = [];
  bool _isFetchingList = true;
  final Map<String, bool> _loadingStatus = {};
  final Map<String, Future<File?>> _activeDownloads = {};

  List<Map<String, dynamic>> get notes => _notes;
  bool get isFetchingList => _isFetchingList;
  bool isLoading(String url) => _loadingStatus[url] ?? false;

  Future<bool> isNoteValid(String url) async {
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
      if (file == null) debugPrint('Notes download failed => $url');
      return file;
    } catch (e) {
      debugPrint('Notes download error => $e');
      return null;
    }
  }

  Future<void> fetchNotes(dynamic chapterId) async {
    _isFetchingList = true;
    _notes = [];
    notifyListeners();

    try {
      final List<dynamic> rawData = await StudentService.fetchNotes(chapterId);
      final List<dynamic> cleanData = jsonDecode(jsonEncode(rawData));
      _notes = cleanData.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      _notes = [];
      debugPrint('Notes Provider Error => $e');
    } finally {
      _isFetchingList = false;
      notifyListeners();
    }
  }

  bool _isInvalidUrl(String url) =>
      url.trim().isEmpty || url.trim().toLowerCase() == 'null';
}
