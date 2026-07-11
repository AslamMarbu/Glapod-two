import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/student_service.dart';
import '../utils/file_utils.dart';

class EnglishMasterProvider with ChangeNotifier {
  List<Map<String, dynamic>> _grammarList = [];
  bool _isFetchingList = true;

  final Map<String, bool> _loadingStatus = {};

  List<Map<String, dynamic>> get grammarList => _grammarList;
  bool get isFetchingList => _isFetchingList;

  bool isLoading(String url) => _loadingStatus[url] ?? false;

  Future<bool> isPdfValid(String url) async =>
      (await FileUtils.getValidCache(url)) != null;

  Future<File?> downloadFile(String url) async {
    if (url.isEmpty || url == "null") return null;

    _loadingStatus[url] = true;
    notifyListeners();

    try {
      return await FileUtils.downloadFile(url);
    } catch (e) {
      debugPrint("Download Error : $e");
      return null;
    } finally {
      _loadingStatus[url] = false;
      notifyListeners();
    }
  }

  Future<void> fetchGrammarPdfs() async {
    _isFetchingList = true;
    _grammarList = [];
    notifyListeners();

    try {
      final List<dynamic> rawData = await StudentService.fetchEnglishGrammar();

      final String bridge = jsonEncode(rawData);
      final List<dynamic> cleanData = jsonDecode(bridge);

      _grammarList = cleanData
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      debugPrint("Grammar Error : $e");
    } finally {
      _isFetchingList = false;
      notifyListeners();
    }
  }
}
