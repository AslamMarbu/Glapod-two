import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiCacheService {
  static String _normalizeKey(String endpoint) {
    final normalized = endpoint
        .replaceAll('/', '_')
        .replaceAll('-', '_')
        .replaceAll(':', '_')
        .replaceAll('?', '_')
        .replaceAll('&', '_')
        .replaceAll('=', '_')
        .replaceAll(RegExp(r'^_'), '');

    return 'api_cache_$normalized';
  }

  /// Save API response
  static Future<void> cacheData(String endpoint, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();

    final String key = _normalizeKey(endpoint);

    await prefs.setString(key, jsonEncode(data));
  }

  /// Get cached API response
  static Future<dynamic> getCachedData(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();

    final String key = _normalizeKey(endpoint);

    final String? cachedData = prefs.getString(key);

    if (cachedData == null) {
      return null;
    }

    try {
      return jsonDecode(cachedData);
    } catch (_) {
      // Remove corrupted cache
      await prefs.remove(key);
      return null;
    }
  }

  /// Clear one exact cached endpoint
  static Future<void> clearCache(String endpoint) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_normalizeKey(endpoint));
  }

  /// Clear all API caches created by this service
  ///
  /// This does NOT remove login/token/student data.
  static Future<void> clearAllApiCache() async {
    final prefs = await SharedPreferences.getInstance();

    final keys = prefs.getKeys();

    final cacheKeys = keys.where((key) => key.startsWith('api_cache_'));

    for (final key in cacheKeys) {
      await prefs.remove(key);
    }
  }
}
