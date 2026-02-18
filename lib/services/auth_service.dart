import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl =
      "https://marbutechnologies.in/projects/Edu-picks/api/student";

  // ================= SEND OTP =================
  static Future<Map<String, dynamic>> sendOtp(String mobile) async {
    try {
      final url = Uri.parse("$baseUrl/send-otp");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "mobile": mobile,
        }),
      );

      final data = jsonDecode(response.body);

      return {
        "status": data["status"] == true || data["status"] == "true",
        "message": data["message"] ?? "Something went wrong"
      };
    } catch (e) {
      return {
        "status": false,
        "message": "Network error"
      };
    }
  }

  // ================= VERIFY OTP =================
  static Future<Map<String, dynamic>> verifyOtp(
      String mobile, String otp) async {
    try {
      final url = Uri.parse("$baseUrl/verify-otp");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "mobile": mobile,
          "otp": otp,
        }),
      );

      final data = jsonDecode(response.body);

      // Save token if login successful
      if (data["status"] == true && data["token"] != null) {
        await saveToken(data["token"]);
      }

      return {
        "status": data["status"] == true || data["status"] == "true",
        "message": data["message"] ?? "Invalid OTP",
        "token": data["token"]
      };
    } catch (e) {
      return {
        "status": false,
        "message": "Network error"
      };
    }
  }

  // ================= SAVE TOKEN =================
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("token", token);
  }

  // ================= GET TOKEN =================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("token");
  }

  // ================= LOGOUT =================
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");
  }
}
