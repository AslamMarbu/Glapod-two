import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/student_service.dart';

class GKMasterProvider with ChangeNotifier {
  // ============================================================
  // STORAGE KEY
  // ============================================================

  static const String _categoriesCacheKey = 'gk_master_categories_cache';

  // ============================================================
  // STATE
  // ============================================================

  List<dynamic> _categories = [];

  Map<String, dynamic>? _selectedCategory;

  bool _isLoadingCategories = false;
  bool _isLoadingContents = false;

  String? _categoryError;
  String? _contentError;

  // ============================================================
  // GETTERS
  // ============================================================

  List<dynamic> get categories => _categories;

  Map<String, dynamic>? get selectedCategory => _selectedCategory;

  bool get isLoadingCategories => _isLoadingCategories;

  bool get isLoadingContents => _isLoadingContents;

  String? get categoryError => _categoryError;

  String? get contentError => _contentError;

  // ============================================================
  // LOAD CATEGORIES
  // ============================================================

  Future<void> loadCategories() async {
    _categoryError = null;

    // ----------------------------------------------------------
    // 1. Load cached categories first
    // ----------------------------------------------------------

    await _loadCachedCategories();

    // ----------------------------------------------------------
    // 2. If cached categories exist,
    //    show them immediately.
    // ----------------------------------------------------------

    if (_categories.isNotEmpty) {
      _isLoadingCategories = false;

      notifyListeners();

      // --------------------------------------------------------
      // Refresh from API silently in background.
      // --------------------------------------------------------

      _refreshCategoriesFromApi();

      return;
    }

    // ----------------------------------------------------------
    // 3. No cached data.
    //    This is the first load.
    // ----------------------------------------------------------

    _isLoadingCategories = true;

    notifyListeners();

    await _refreshCategoriesFromApi();
  }

  // ============================================================
  // LOAD CACHED CATEGORIES
  // ============================================================

  Future<void> _loadCachedCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? cachedData = prefs.getString(_categoriesCacheKey);

      if (cachedData == null || cachedData.isEmpty) {
        return;
      }

      final dynamic decoded = jsonDecode(cachedData);

      if (decoded is List) {
        _categories = decoded;

        debugPrint(
          'GK Master: Loaded ${_categories.length} categories from cache.',
        );
      }
    } catch (e) {
      debugPrint('GK Master Cached Categories Error: $e');
    }
  }

  // ============================================================
  // REFRESH CATEGORIES FROM API
  // ============================================================

  Future<void> _refreshCategoriesFromApi() async {
    try {
      final List<dynamic> freshCategories =
          await StudentService.fetchGKMasterCategories();

      // --------------------------------------------------------
      // Update provider
      // --------------------------------------------------------

      _categories = freshCategories;

      _categoryError = null;

      debugPrint(
        'GK Master: Loaded ${_categories.length} categories from API.',
      );

      // --------------------------------------------------------
      // Save categories locally
      // --------------------------------------------------------

      await _saveCategoriesToCache();
    } catch (e) {
      debugPrint('GK Master Provider Categories Error: $e');

      // --------------------------------------------------------
      // IMPORTANT:
      //
      // If cached categories already exist, DON'T remove them.
      // The user can continue using the page even if API fails.
      // --------------------------------------------------------

      if (_categories.isEmpty) {
        _categoryError = e.toString();
        _categories = [];
      }
    } finally {
      _isLoadingCategories = false;

      notifyListeners();
    }
  }

  // ============================================================
  // SAVE CATEGORIES TO CACHE
  // ============================================================

  Future<void> _saveCategoriesToCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(_categoriesCacheKey, jsonEncode(_categories));

      debugPrint('GK Master: Categories saved to local cache.');
    } catch (e) {
      debugPrint('GK Master Save Cache Error: $e');
    }
  }

  // ============================================================
  // LOAD CATEGORY IMAGES / CONTENTS
  // ============================================================

  Future<void> loadCategoryContents(dynamic categoryId) async {
    _isLoadingContents = true;
    _contentError = null;
    _selectedCategory = null;

    notifyListeners();

    try {
      final response = await StudentService.fetchGKMasterCategoryContents(
        categoryId,
      );

      debugPrint('GK Master Provider Response: $response');

      if (response['status'] == true) {
        _selectedCategory = response;
      } else {
        _selectedCategory = null;

        _contentError =
            response['message']?.toString() ?? 'Failed to load images.';
      }
    } catch (e) {
      debugPrint('GK Master Provider Images Error: $e');

      _selectedCategory = null;

      _contentError = e.toString();
    } finally {
      _isLoadingContents = false;

      notifyListeners();
    }
  }

  // ============================================================
  // CLEAR
  // ============================================================

  void clearCategory() {
    _selectedCategory = null;
    _contentError = null;

    notifyListeners();
  }

  // ============================================================
  // REFRESH CATEGORIES
  // ============================================================

  Future<void> refreshCategories() async {
    // ----------------------------------------------------------
    // Force API refresh.
    //
    // Existing cached categories remain visible while refreshing.
    // ----------------------------------------------------------

    _categoryError = null;

    if (_categories.isEmpty) {
      _isLoadingCategories = true;
      notifyListeners();
    }

    await _refreshCategoriesFromApi();
  }

  // ============================================================
  // REFRESH CATEGORY CONTENTS
  // ============================================================

  Future<void> refreshCategoryContents(dynamic categoryId) async {
    await loadCategoryContents(categoryId);
  }

  // ============================================================
  // CLEAR CATEGORY CACHE
  // ============================================================

  Future<void> clearCategoriesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.remove(_categoriesCacheKey);

      _categories = [];

      _categoryError = null;

      notifyListeners();

      debugPrint('GK Master: Category cache cleared.');
    } catch (e) {
      debugPrint('GK Master Clear Cache Error: $e');
    }
  }
}
