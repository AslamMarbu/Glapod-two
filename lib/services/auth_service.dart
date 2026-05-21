import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:glapod/constants/api_constants.dart';
import 'package:glapod/storage/local_storage_service.dart';

class AuthService {
  static const String baseUrl = ApiConstants.baseUrl;

  // --- Registration & OTP ---
  static Future<Map<String, dynamic>> registerAndSendOtp({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String device,
    required String country, // New Field
    required String state,   // New Field
  }) async {
    final url = Uri.parse('$baseUrl/api/student/register/otp');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "phone": phone,
          "password": password,
          "device_info": device,
          "country": country, // Pass to API
          "state": state,     // Pass to API
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"status": false, "message": "Network error occurred"};
    }
  }

  static Future<Map<String, dynamic>> otpVerification({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String otp,
    required String device,
    required String country, // New Field
    required String state,   // New Field
  }) async {
    final url = Uri.parse('$baseUrl/api/student/register/verification');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "phone": phone,
          "password": password,
          "otp": otp,
          "device_info": device,
          "country": country, // Pass to API
          "state": state,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"status": false, "message": "Network error occurred"};
    }
  }

  // --- Login ---
  static Future<Map<String, dynamic>> loginAuth({
    required String email,
    required String password,
    required String deviceId
  }) async {
    final url = Uri.parse('$baseUrl/api/student/login');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "device_id": deviceId,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"status": false, "message": "Network error occurred"};
    }
  }

  // lib/services/auth_service.dart
  static Future<Map<String, dynamic>> enterPurchaseKey({
    required String key,
    required String deviceId,
  }) async {
    final url = Uri.parse('$baseUrl/api/enter/purchase-key');
    final String? token = await LocalStorageService.getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "purchase_key": key,
          "device_info": deviceId,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "success": responseData['status'] == true,
          "message": responseData['popup'] != null ? responseData['popup']['message'] : "",
        };
      } else {
        return {"success": false, "message": responseData['message'] ?? "Invalid key"};
      }
    } catch (e) {
      return {"success": false, "message": "Network error"};
    }
  }

  // STEP 2: Finalize Activation
  static Future<Map<String, dynamic>> activatePurchaseKey({
    required String key,
    required String deviceId,
  }) async {
    final url = Uri.parse('$baseUrl/api/activate-purchase-key');
    final String? token = await LocalStorageService.getToken();

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "purchase_key": key,
          "device_info": deviceId,
        }),
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return {
        "success": responseData['status'] == true,
        "message": responseData['message'] ?? "Activation Successful",
      };
    } catch (e) {
      return {"success": false, "message": "Activation failed"};
    }
  }

  // --- Password Recovery ---
  static Future<Map<String, dynamic>> forgotPasswordRequest({required String email}) async {
    final url = Uri.parse('$baseUrl/api/student/forgot-password');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"status": false, "message": "Network error occurred"};
    }
  }

  static Future<Map<String, dynamic>> forgotPasswordVerifyOtp({
    required String email,
    required String otp,
  }) async {
    final url = Uri.parse('$baseUrl/api/student/verify-otp');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "otp": otp,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"status": false, "message": "Network error occurred"};
    }
  }

  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    final url = Uri.parse('$baseUrl/api/student/reset-password');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "otp": otp,
          "password": password,
          "password_confirmation": passwordConfirmation,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {"status": false, "message": "Network error occurred"};
    }
  }
}