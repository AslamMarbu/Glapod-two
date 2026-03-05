import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:glapod/utils/device_utils.dart';
import 'package:glapod/constants/api_constants.dart';

class AuthService {
  static const String baseUrl =ApiConstants.baseUrl;

  // ================= SEND OTP =================
  static Future<Map<String, dynamic>> sendOtp(String mobile) async {
    try {
      final url = Uri.parse("$baseUrl/api/student/send-otp");

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

      String? otp = data["otp"]?.toString();
      String baseMessage = data["message"] ?? "Operation successful";

      return {
        "status": data["status"] == true || data["status"] == "true",
        // If otp is not null, append it. Otherwise, just use the message.
        "message": otp != null ? "$baseMessage. Your OTP is: $otp" : baseMessage,
        "otp": otp,
      };
    } catch (e) {
      return {
        "status": false,
        "message": "Network error"
      };
    }
  }

  // ================= VERIFY OTP =================
  static Future<Map<String, dynamic>> verifyOtp(String mobile, String otp) async {
    try {
      final url = Uri.parse("$baseUrl/api/student/verify-otp");
      final device  = await DeviceService.getUniqueId();

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "mobile": mobile,
          "otp": otp,
          "device":"device"
        }),
      );

      final data = jsonDecode(response.body);

      return {
        "status": data["status"] == true || data["status"] == "true",
        "message": data["message"] ?? "Invalid OTP",
        "token": data["token"],
        "student": data["student"]
      };
    } catch (e) {
      return {
        "status": false,
        "message":"Network Error"
      };
    }
  }
}
