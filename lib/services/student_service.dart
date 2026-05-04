import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:glapod/storage/local_storage_service.dart';
import 'package:glapod/constants/api_constants.dart';
import '../models/question_year_model.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';

class StudentService {
  static Future<void> syncStudentProfile() async {
    try {
      final token = await LocalStorageService.getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse("$baseUrl/api/profile"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == true && data['user'] != null) {
          // USE THE MERGE FUNCTION
          // This keeps your Token but updates EVERYTHING else
          await LocalStorageService.updateStudentFromProfile(data['user']);
        }
      } else if (response.statusCode == 401) {
        // Session expired - clear everything
        await LocalStorageService.logOut();
      }
    } catch (e) {

    }
  }

  static final Dio _dio = Dio();
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

  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    required String classId,
    File? imageFile,
  }) async {
    try {
      final token = await LocalStorageService.getToken();
      var uri = Uri.parse("$baseUrl/api/profile/update");

      var request = http.MultipartRequest("POST", uri);

      request.headers.addAll({
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['class_id'] = classId;

      if (imageFile != null) {
        // MATCHING POSTMAN: The key must be 'image'
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ));
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          "status": true,
          "message": data["message"] ?? "Success",
          "student": data["user"] // Based on your screenshot, the key is "user"
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

  static Future<Map<String, dynamic>?> fetchAllLanguages() async {
    try {
      final token = await LocalStorageService.getToken();
      final response = await http.get(
        Uri.parse("$baseUrl/api/language/all"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 2. Fetch Videos using Path Parameters: /api/study/videos/37/1
  static Future<List<dynamic>> fetchStudyVideos(dynamic chapterId, dynamic languageId) async {
    try {
      final token = await LocalStorageService.getToken();

      // Ensure IDs are strings to safely build the URL path
      final String cId = chapterId.toString();
      final String lId = languageId.toString();

      final response = await http.get(
        Uri.parse("$baseUrl/api/study/videos/$cId/$lId"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Returns the list of videos (adjust the key 'videos' if your API uses 'data')
        return data['videos'] ?? [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> fetchNotes(dynamic chapterId) async {
    // Ensure your baseUrl is correct (e.g., http://marbutechnologies.in/projects/Edu-picks/public)
    final token = await LocalStorageService.getToken();
    final response = await http.get(Uri.parse('$baseUrl/api/study/notes/$chapterId'),
      headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json'
    },);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Directly return the list of notes containing 'id' and 'note_url'
      return data['notes'] ?? [];
    } else {
      throw Exception('Failed to load notes');
    }
  }

  static Future<Map<String, dynamic>> getChapterSolutions(dynamic classId,dynamic subjctId, dynamic chapterId) async {
    final token = await LocalStorageService.getToken();

    try {
      // Hardcoded URL as per your request, usually you'd pass IDs as parameters
      final response = await http.get(
        Uri.parse('$baseUrl/api/textbook-solutions/$classId/$subjctId/$chapterId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json'
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {"status": false, "message": "Server Error"};
    } catch (e) {
      return {"status": false, "message": e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getChaptersList(String subjectId, String classId) async {
    final token = await LocalStorageService.getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/api/question-bank/chapters/list/$classId/$subjectId"),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getQuestionMarkList(String subjectId, String classId) async {
    final token = await LocalStorageService.getToken();
    // Assuming the endpoint for types is similar or specifically provided
    final response = await http.get(
      Uri.parse("$baseUrl/api/question-bank/mark/list/$classId/$subjectId/"),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }


  // Fetch questions filtered by Chapter
  static Future<Map<String, dynamic>> getQuestionsByChapter(String subjectId, String classId, String chapterId) async {
    final token = await LocalStorageService.getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/api/question-bank/chapter/$classId/$subjectId/$chapterId"),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }

// Fetch questions filtered by Marks
  static Future<Map<String, dynamic>> getQuestionsByMark(String subjectId, String classId, String mark) async {
    final token = await LocalStorageService.getToken();
    final response = await http.get(
      Uri.parse("$baseUrl/api/question-bank/mark/$classId/$subjectId/$mark"),
      headers: {'Authorization': 'Bearer $token'},
    );
    return jsonDecode(response.body);
  }



  // Fetch the Years for a specific subject
  Future<QuestionYearModel?> fetchYears(int subjectId) async {
    try {
      final token = await LocalStorageService.getToken();
      final response = await http.get(
          Uri.parse("$baseUrl/api/solved-papers/$subjectId"),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return QuestionYearModel.fromJson(jsonDecode(response.body));
      }
    } catch (e) {

    }
    return null;
  }

  // Fetch the specific sets for a Subject + Year combination
  Future<List<dynamic>?> fetchPaperSets(String subjectId, String year) async {
    try {
      final token = await LocalStorageService.getToken();
      final response = await http.get(
          Uri.parse("$baseUrl/api/solved-papers/list/$subjectId/$year"),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final decodedData = jsonDecode(response.body);
        return decodedData['data']; // Returns the list of paper sets
      }
    } catch (e) {

    }
    return null;
  }

  static Future<List<dynamic>> fetchSolvedPapers(String classId) async {
    final token = await LocalStorageService.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/solved-papers/all/$classId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(response.body);
      return body['data'] ?? [];
    } else {
      throw Exception('Failed to load solved papers');
    }
  }

  // Add to lib/services/student_service.dart

  static Future<List<dynamic>> fetchYearWisePapers(String subjectId, String year) async {
    final token = await LocalStorageService.getToken();
    // Using the structure: {{url}}/api/solved-papers/{subjectId}/{year}
    final response = await http.get(
      Uri.parse('$baseUrl/api/solved-papers/$subjectId/$year'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> body = json.decode(response.body);
      // Adjust 'data' or 'papers' based on your actual API response key
      return body['data'] ?? [];
    } else {
      throw Exception('Failed to load paper sets');
    }
  }


  static Future<bool> toggleBookmark(String type, String id) async {
    try {
      final token = await LocalStorageService.getToken();
      final url = Uri.parse("$baseUrl/api/bookmark/$type/$id");

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == true || data['status'] == 1;
      }
      return false;
    } catch (e) {

      return false;
    }
  }

  // Add this inside StudentService class in lib/services/student_service.dart

  static Future<List<dynamic>> fetchGuessNameCategories() async {
    try {
      final token = await LocalStorageService.getToken();
      final response = await http.get(
        Uri.parse("$baseUrl/api/prediction/guess-name/category"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data["status"] == true) {
          return data["categories"] ?? [];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
// 1. Guess Name Question
  static Future<Map<String, dynamic>> fetchGuessNameQuestion(
      int categoryId,
      String level,
      {String? status} // Optional status parameter
      ) async {
    try {
      final token = await LocalStorageService.getToken();

      Map<String, dynamic> map = {
        'cate_id': categoryId.toString(),
        'level': level,
      };

      // If status is provided, add it to the map
      if (status != null) {
        map['status'] = status;
      }

      FormData formData = FormData.fromMap(map);

      Response response = await _dio.post(
        "$baseUrl/api/prediction/guess-name/question",
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      return response.data;
    } catch (e) {
      return {"status": false, "message": "Connection error", "completed": false};
    }
  }

  static Future<Map<String, dynamic>> submitGuessNameFeedback({
    required String guessNameId,
    required String feedback,
  }) async {
    try {
      final token = await LocalStorageService.getToken();
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/api/prediction/guess-name/submit-feedback"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "guess_name_id": guessNameId,
          "feedback": feedback,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"status": false, "message": "Failed to submit feedback"};
      }
    } catch (e) {
      return {"status": false, "message": "API Error: $e"};
    }
  }


  static Future<Map<String, dynamic>> getGuessNameQuestionGrid({
    required int categoryId,
    required String level,
  }) async {
    try {
      final token = await LocalStorageService.getToken();
      final response = await http.post(
        Uri.parse("${ApiConstants.baseUrl}/api/prediction/guess-name/question/all"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "cate_id": categoryId, //
          "level": level,        //
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"status": false, "message": "Failed to load grid data"};
      }
    } catch (e) {
      return {"status": false, "message": "API Error: $e"};
    }
  }

// 2. Past Tense Question
  static Future<Map<String, dynamic>> fetchPastTenseQuestion(
      String level,
      {String? status} // Optional status parameter
      ) async {
    try {
      final token = await LocalStorageService.getToken();

      Map<String, dynamic> map = {
        'level': level,
      };

      // Add status if it exists
      if (status != null) {
        map['status'] = status;
      }

      FormData formData = FormData.fromMap(map);

      Response response = await _dio.post(
        "$baseUrl/api/prediction/find-tense/question",
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

// 3. Opposite Words Question
  static Future<Map<String, dynamic>> fetchOppositeQuestion(
      String level,
      {String? status} // Optional status parameter
      ) async {
    try {
      final token = await LocalStorageService.getToken();

      Map<String, dynamic> map = {
        'level': level,
      };

      // Add status if it exists
      if (status != null) {
        map['status'] = status;
      }


      FormData formData = FormData.fromMap(map);

      Response response = await _dio.post(
        "$baseUrl/api/prediction/opposite-words/question",
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ),
      );

      return response.data;
    } catch (e) {
      return {
        "status": false,
        "message": "Connection error: Please check your internet.",
        "completed": false
      };
    }
  }

  static Future<Map<String, dynamic>> fetchNotifications() async {
    try {
      final token = await LocalStorageService.getToken();

      // We must parse the URL string into a Uri object for the http package
      final url = Uri.parse("$baseUrl/api/notifications");

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        // Checking your specific "status": true logic
        if (data['status'] == true || data['status'] == 1) {
          return data;
        } else {
          throw Exception(data['message'] ?? "Failed to load notifications");
        }
      } else {
        throw Exception("Server Error: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> fetchBookmarks() async {
    try {
      final token = await LocalStorageService.getToken();
      final response = await http.get(
        Uri.parse("$baseUrl/api/bookmark/list"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {

      return null;
    }
  }

  static Future<List<dynamic>> fetchSamplePapers(String classId, String subjectId) async {
    try {
      final token = await LocalStorageService.getToken();
      final response = await http.get(
        // Corrected URL structure based on your prompt
        Uri.parse("$baseUrl/api/study/subjects/sample-papers/$classId/$subjectId"),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          return data['papers'] ?? [];
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

}




