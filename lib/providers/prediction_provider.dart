import 'package:flutter/material.dart';
import '../services/student_service.dart';

class PredictionProvider with ChangeNotifier {
  // Keep it as dynamic, but initialize as an empty growable list to prevent type errors
  List<dynamic> _categories = [];
  List<dynamic> _wordMasterPages = [];
  bool _isLoading = true;
  bool _isLoadingWordMasterPages = false;

  List<dynamic> get categories => _categories;
  List<dynamic> get wordMasterPages => _wordMasterPages;
  bool get isLoading => _isLoading;
  bool get isLoadingWordMasterPages => _isLoadingWordMasterPages;

  final List<String> displayLabels = ["Beginner", "Intermediate", "Advanced"];

  /// Maps UI labels to API keys (Simplified using .toLowerCase())
  String mapToApi(String displayLabel) {
    return displayLabel.toLowerCase();
  }

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();
    try {
      // Basic fix: Use List.from() to ensure Dart safely casts whatever the service returns
      final data = await StudentService.fetchGuessNameCategories();
      _categories = List<dynamic>.from(data ?? []);
    } catch (e) {
      _categories = [];
      debugPrint("PredictionProvider Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch uploaded Word Master page images from the Laravel API.
  Future<void> fetchWordMasterPages() async {
    _isLoadingWordMasterPages = true;
    notifyListeners();

    try {
      final data = await StudentService.fetchWordMasterPages();
      _wordMasterPages = List<dynamic>.from(data ?? []);
    } catch (e) {
      debugPrint("Word Master pages error: $e");
      // Keep previously loaded pages if a temporary refresh fails.
      if (_wordMasterPages.isEmpty) {
        _wordMasterPages = [];
      }
    } finally {
      _isLoadingWordMasterPages = false;
      notifyListeners();
    }
  }

  String _normalizePageName(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Returns the uploaded image URL for a page name, if one exists.
  String? imageForPage(String pageName) {
    final normalizedName = _normalizePageName(pageName);

    for (final dynamic item in _wordMasterPages) {
      if (item is! Map) continue;

      final storedName = (item['page_name'] ?? '').toString();
      if (_normalizePageName(storedName) != normalizedName) continue;

      final image = (item['image'] ?? '').toString().trim();
      if (image.isNotEmpty && image.toLowerCase() != 'null') {
        return image;
      }
    }

    return null;
  }
}
