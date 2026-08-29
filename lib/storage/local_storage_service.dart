import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum LicenseStatus {
  activated, // Subscription is active
  expired, // Subscription has ended
  trialing, // Still in the free trial period
  trialExpired,
  needProfileUpdate, // Trial over, needs to buy/activate
}

class LocalStorageService {
  static const String _tokenKey = "auth_token";

  static const String _keyToken = "auth_token";
  static const String _keyStudent = "student_data";
  static const String _keyIsLoggedIn = "is_logged_in";
  static const String _keyTrialDays = "remaining_trial_days";
  static const String _keyIsActivated = "is_activated";

  static Future<void> saveUserSession({
    required String token,
    required Map<String, dynamic> studentData,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyStudent, jsonEncode(studentData));

    final String? createdOn = studentData['account_created_on']?.toString();

    final int trialAllowed =
        int.tryParse(studentData['trail_time']?.toString() ?? '15') ?? 15;

    int remaining = trialAllowed;

    if (createdOn != null && createdOn.isNotEmpty) {
      try {
        final DateTime createdAt = DateTime.parse(createdOn);
        final int daysUsed = DateTime.now().difference(createdAt).inDays;

        remaining = (trialAllowed - daysUsed).clamp(0, trialAllowed);
      } catch (_) {
        remaining = trialAllowed;
      }
    }

    await prefs.setInt(_keyTrialDays, remaining);
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  static Future<void> updateStudentData(
    Map<String, dynamic> studentData,
  ) async {
    await updateStudentFromProfile(studentData);
  }

  static Future<void> updateStudentFromProfile(
    Map<String, dynamic> user,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get the student data already saved from login
    Map<String, dynamic> existingStudent = {};

    final String? existingJson = prefs.getString(_keyStudent);

    if (existingJson != null && existingJson.isNotEmpty) {
      try {
        existingStudent = Map<String, dynamic>.from(jsonDecode(existingJson));
      } catch (e) {
        existingStudent = {};
      }
    }

    // MERGE instead of replacing.
    // Existing login fields such as:
    // key, trail_time, account_created_on,
    // subscription_start, subscription_end
    // will remain unless the profile API provides newer values.
    final Map<String, dynamic> mergedStudent = {...existingStudent, ...user};

    // Save merged student
    await prefs.setString(_keyStudent, jsonEncode(mergedStudent));

    // Recalculate trial days
    final String? createdOn = mergedStudent['account_created_on']?.toString();

    if (createdOn != null && createdOn.isNotEmpty) {
      try {
        final DateTime createdAt = DateTime.parse(createdOn);

        final int trialAllowed =
            int.tryParse(mergedStudent['trail_time']?.toString() ?? '15') ?? 15;

        final int daysUsed = DateTime.now().difference(createdAt).inDays;

        final int remaining = (trialAllowed - daysUsed).clamp(0, trialAllowed);

        await prefs.setInt(_keyTrialDays, remaining);
      } catch (e) {
        // Keep the previous trial value if date parsing fails.
      }
    }
  }

  static Future<void> logOut() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyToken);
    await prefs.remove(_keyStudent);
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyTrialDays);
    await prefs.remove(_keyIsActivated);
  }

  static Future<bool> isUserLoggedIn() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString(_keyToken);
    return token != null && token.isNotEmpty;
  }

  static Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  static Future<void> saveTrialDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTrialDays, days);
  }

  static Future<int> getTrialDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyTrialDays) ?? 0;
  }

  static Future<void> saveLicenseStatus(bool isActivated) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsActivated, isActivated);
  }

  static Future<bool> isLicenseActivated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsActivated) ?? false;
  }

  static Future<Map<String, dynamic>?> getStudent() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieve the JSON string we saved earlier
    String? studentJson = prefs.getString(_keyStudent);

    if (studentJson != null && studentJson.isNotEmpty) {
      try {
        // Convert the String back into a Map
        return jsonDecode(studentJson) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  static Future<LicenseStatus> getLicenseStatus() async {
    final student = await LocalStorageService.getStudent();
    if (student == null) return LicenseStatus.trialExpired;

    // Use .toString() to avoid TypeError if the value is an int/double
    final String key =
        student['key']?.toString().toLowerCase() ?? "unavailable";
    final String subEnd = student['subscription_end']?.toString() ?? "";
    final String createdOnStr = student['account_created_on']?.toString() ?? "";

    // classId can be int, String, or null, so we handle it safely
    final dynamic rawClassId = student['class_id'];
    final int classId = (rawClassId is int)
        ? rawClassId
        : int.tryParse(rawClassId?.toString() ?? "0") ?? 0;

    LicenseStatus currentStatus = LicenseStatus.trialExpired;
    DateTime now = DateTime.now();

    // --- 1. ACTIVATED LOGIC ---
    if (key == "activated") {
      if (subEnd.isNotEmpty) {
        try {
          DateTime expiryDate = DateTime.parse(subEnd);
          currentStatus = now.isBefore(expiryDate)
              ? LicenseStatus.activated
              : LicenseStatus.expired;
        } catch (e) {
          currentStatus = LicenseStatus.expired;
        }
      } else {
        currentStatus = LicenseStatus.expired;
      }
    }
    // --- 2. TRIAL LOGIC ---
    else if (key == "trial") {
      if (createdOnStr.isNotEmpty) {
        try {
          final DateTime createdOn = DateTime.parse(createdOnStr);

          final int duration =
              int.tryParse(student['trail_time']?.toString() ?? "15") ?? 15;

          final DateTime expiry = createdOn.add(Duration(days: duration));

          currentStatus = now.isBefore(expiry)
              ? LicenseStatus.trialing
              : LicenseStatus.trialExpired;
        } catch (e) {
          currentStatus = LicenseStatus.trialExpired;
        }
      } else {
        currentStatus = LicenseStatus.trialExpired;
      }
    }

    // --- 3. PROFILE CHECK ---
    // If status is valid, check if classId is missing (0 or null)
    if ((currentStatus == LicenseStatus.activated ||
            currentStatus == LicenseStatus.trialing) &&
        (classId == 0)) {
      return LicenseStatus.needProfileUpdate;
    }

    return currentStatus;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('studentData');
    await prefs.remove('license_status');
  }
}
