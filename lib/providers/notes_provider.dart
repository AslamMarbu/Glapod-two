import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/student_service.dart';
import '../utils/file_utils.dart';

class NotesProvider with ChangeNotifier {
  List<Map<String, dynamic>> _notes = [];
  bool _isFetchingList = true;
  final Map<String, bool> _loadingStatus = {};

  List<Map<String, dynamic>> get notes => _notes;
  bool get isFetchingList => _isFetchingList;
  bool isLoading(String url) => _loadingStatus[url] ?? false;

  /// Checks cache validity
  Future<bool> isNoteValid(String url) async => (await FileUtils.getValidCache(url)) != null;

  /// 🔹 CLEANED: Only handles UI state notification
  Future<File?> downloadFile(String url) async {
    if (url.isEmpty || url == "null") return null;

    _loadingStatus[url] = true;
    notifyListeners();

    try {
      // Logic is now centralized
      return await FileUtils.downloadFile(url);
    } catch (e) {
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

      // 🔹 THE WEB BRIDGE: Destroys problematic JS pointers
      final String bridge = jsonEncode(rawData);
      final List<dynamic> cleanData = jsonDecode(bridge);

      _notes = cleanData.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      debugPrint("Provider Error: $e");
    } finally {
      _isFetchingList = false;
      notifyListeners();
    }
  }
}