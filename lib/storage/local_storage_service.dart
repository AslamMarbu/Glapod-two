import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LocalStorageService {
  static const String _tokenKey = "auth_token";

  // Save Token
  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Get Token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Remove Token (logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static const String _loggedKey = "isUserLogged";
  static const String _loggedUserId = "userId";

  static Future<void> setLoggedUser(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedKey, true);
    await prefs.setInt(_loggedUserId, userId);
  }
  static Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_loggedUserId);

    return userId != null && userId.isNotEmpty;
  }

    static Future<void> LogoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_loggedUserId);
    clearToken();
  }


  //Logged Student data
  static const String _studentKey = "student_data";

  static Future<void> setStudent(Map<String, dynamic> studentData) async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = jsonEncode(studentData);
    await prefs.setString(_studentKey, encodedData);
  }

  static Future<Map<String, dynamic>?> getStudent() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString(_studentKey);

    if (data != null) {
      return jsonDecode(data);
    }
    return null;

  }

  static Future<void> removeStudent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_studentKey);
  }

  static Future<bool> hasStudent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_studentKey);
  }
}