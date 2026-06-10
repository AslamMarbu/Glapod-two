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

    // 1. Save the Bearer Token
    await prefs.setString(_keyToken, token);

    // 2. Save the Student Profile
    String studentJson = jsonEncode(studentData);
    await prefs.setString(_keyStudent, studentJson);

    // 3. AUTOMATIC TRIAL CALCULATION
    DateTime createdAt = studentData['account_created_on'] != null
        ? DateTime.parse(studentData['account_created_on'])
        : DateTime.now();

    int trialAllowed = studentData['trail_time'] ?? 7;
    int daysUsed = DateTime.now().difference(createdAt).inDays;
    int remaining = trialAllowed - daysUsed;

    // Save the integer directly for easy access in UI
    await prefs.setInt(_keyTrialDays, remaining);
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  static Future<void> updateStudentData(
    Map<String, dynamic> studentData,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Update Profile
    await prefs.setString(_keyStudent, jsonEncode(studentData));

    // Update Trial Math (Same as above)
    DateTime createdAt = studentData['account_created_on'] != null
        ? DateTime.parse(studentData['account_created_on'])
        : DateTime.now();
    int trialAllowed = studentData['trail_time'] ?? 7;
    int daysUsed = DateTime.now().difference(createdAt).inDays;
    int remaining = trialAllowed - daysUsed;

    await prefs.setInt(_keyTrialDays, remaining);
  }

  static Future<void> updateStudentFromProfile(
    Map<String, dynamic> user,
  ) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // 1. Overwrite the student data (The 'user' from Profile API)
    String studentJson = jsonEncode(user);
    await prefs.setString(_keyStudent, studentJson);

    // 2. Re-calculate and Overwrite Trial Days (Same logic as your Login)
    if (user['account_created_on'] != null) {
      DateTime createdAt = DateTime.parse(user['account_created_on']);
      int trialAllowed = user['trail_time'] ?? 7;
      int daysUsed = DateTime.now().difference(createdAt).inDays;
      int remaining = trialAllowed - daysUsed;

      // Update the specific trial days key
      await prefs.setInt(_keyTrialDays, remaining);
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
          DateTime createdOn = DateTime.parse(createdOnStr);
          // Ensure duration is handled as int even if it comes as a string
          int duration =
              int.tryParse(student['trail_time']?.toString() ?? "7") ?? 7;
          DateTime expiry = createdOn.add(Duration(days: duration));

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
