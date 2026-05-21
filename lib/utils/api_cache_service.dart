import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiCacheService {

  /// Formats the endpoint into a clean storage key
  /// Example: /api/study/get-subjects/3 -> api_study_get_subjects_3
  static String _normalizeKey(String endpoint) {
    return endpoint.replaceAll('/', '_').replaceAll('-', '_').replaceAll(RegExp(r'^_'), '');
  }

  /// 🔹 Generic Save: Accepts any endpoint and any data (List or Map)
  static Future<void> cacheData(String endpoint, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = _normalizeKey(endpoint);
    await prefs.setString(key, jsonEncode(data));
  }

  /// 🔹 Generic Get: Retrieves data based on the endpoint
  static Future<dynamic> getCachedData(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = _normalizeKey(endpoint);
    final String? cachedData = prefs.getString(key);

    if (cachedData != null) {
      return jsonDecode(cachedData);
    }
    return null;
  }

  /// Optional: Clear cache for a specific endpoint
  static Future<void> clearCache(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_normalizeKey(endpoint));
  }
}