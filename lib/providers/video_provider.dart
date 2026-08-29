import 'package:flutter/material.dart';
import '../services/student_service.dart';

class VideoProvider with ChangeNotifier {
  List<dynamic> _languages = [];
  List<dynamic> _videos = [];

  bool _isPageLoading = true;
  bool _isVideosLoading = false;

  int? _selectedLanguageId;
  String _selectedLanguageName = "";

  // Getters
  List<dynamic> get languages => _languages;
  List<dynamic> get videos => _videos;
  bool get isPageLoading => _isPageLoading;
  bool get isVideosLoading => _isVideosLoading;
  int? get selectedLanguageId => _selectedLanguageId;
  String get selectedLanguageName => _selectedLanguageName;

  // Utility to handle mixed types from API
  int? toSafeInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    return int.tryParse(val.toString());
  }

  Future<void> initialFetch(dynamic chapterId) async {
    _isPageLoading = true;
    notifyListeners();

    try {
      final langResponse = await StudentService.fetchAllLanguages();
      if (langResponse != null && langResponse['status'] == true) {
        _languages = langResponse['languages'] ?? [];

        if (_languages.isNotEmpty) {
          _selectedLanguageId = toSafeInt(_languages[0]['id']);
          _selectedLanguageName = _languages[0]['language'] ?? "";
          await loadVideos(chapterId);
        }
      }
    } catch (e) {
      debugPrint("Video Provider Init Error: $e");
    } finally {
      _isPageLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadVideos(dynamic chapterId) async {
    if (_selectedLanguageId == null) return;

    _isVideosLoading = true;
    _videos = [];
    notifyListeners();

    try {
      debugPrint("========== VIDEO FETCH ==========");
      debugPrint("Chapter ID: $chapterId");
      debugPrint("Language ID: $_selectedLanguageId");
      debugPrint("Language: $_selectedLanguageName");

      final result = await StudentService.fetchStudyVideos(
        chapterId,
        _selectedLanguageId,
      );

      debugPrint("Videos returned: ${result.length}");
      debugPrint("Video data: $result");

      _videos = result;
    } catch (e, stackTrace) {
      debugPrint("VIDEO FETCH ERROR: $e");
      debugPrint("$stackTrace");

      _videos = [];
    } finally {
      _isVideosLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectLanguage(dynamic languageId, dynamic chapterId) async {
    final int? id = toSafeInt(languageId);

    if (id == null) return;

    _selectedLanguageId = id;

    // Find selected language name from languages list
    final selectedLanguage = _languages.firstWhere(
      (lang) => toSafeInt(lang['id']) == id,
      orElse: () => null,
    );

    if (selectedLanguage != null) {
      _selectedLanguageName = selectedLanguage['language']?.toString() ?? "";
    } else {
      _selectedLanguageName = "";
    }

    notifyListeners();

    await loadVideos(chapterId);
  }
}
