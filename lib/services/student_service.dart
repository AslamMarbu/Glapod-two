import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:glapod/storage/local_storage_service.dart';
import 'package:glapod/constants/api_constants.dart';
import 'package:glapod/utils/logger.dart';

class StudentService {
  static const String baseUrl =ApiConstants.baseUrl;

  static Future<List<dynamic>> fetchClasses() async {
    try {

      String? token = await LocalStorageService.getToken();

      if (token == null) {
        throw Exception("Token not found");
      }

      final response = await http.get(
        Uri.parse("$baseUrl/api/class/all"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data["status"] == true &&
            data["allclass"] != null) {
          return data["allclass"];
        } else {
          return [];
        }
      } else {
        throw Exception(
            "Failed to load classes: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("API Error: $e");
    }
  }

  static Future<Map<String, dynamic>> updateProfile({ required String name,required String email,required String classId}) async {
    try {
      final token = await LocalStorageService.getToken();

      var headers = {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      };

      var body = json.encode({
        "name": name,
        "email": email,
        "class_id": classId, // Send selection to server
      });

      var response = await http.post(
        Uri.parse("$baseUrl/api/profile/update"),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          "status": true,
          "message": "Profile Updated Successfully",
          "student": data["user"]
        };
      } else {
        return {"status": false, "message": "Server Error: ${response.statusCode}"};
      }
    } catch (e) {
      return {"status": false, "message": "Network error: $e"};
    }
  }

  static Future<List<dynamic>> fetchSubjects(String classId) async {
    try {
      final token = await LocalStorageService.getToken();
      var response = await http.get(
        Uri.parse('$baseUrl/api/study/get-subjects/$classId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ✅ CORRECT: Returns the entire list of subjects
        return data['subjects'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> fetchStudyVideos(String chapterId) async {
    try {
      final token = await LocalStorageService.getToken();
      var response = await http.get(
        Uri.parse('$baseUrl/api/study/videos/$chapterId/1'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ✅ CORRECT: Returns the entire list of subjects
        return data['videos'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }


}




