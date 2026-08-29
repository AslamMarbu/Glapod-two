import 'package:dio/dio.dart';

import '../models/gk_master_model.dart';
import 'dio_client.dart';

class GkService {
  Future<List<GkCategory>> fetchCategories() async {
    try {
      final Response response = await DioClient.instance.get(
        '/api/gk-master/categories',
      );

      final data = response.data;

      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> categoryList = data['data'] ?? [];

        return categoryList
            .map((item) => GkCategory.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }

      throw Exception(data['message'] ?? 'Failed to load GK categories');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to load GK categories',
      );
    }
  }

  Future<List<GkZone>> fetchZones({required int categoryId}) async {
    try {
      final Response response = await DioClient.instance.get(
        '/api/gk-master/zones/$categoryId',
      );

      final data = response.data;

      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> zoneList = data['data'] ?? [];

        return zoneList
            .map((item) => GkZone.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }

      throw Exception(data['message'] ?? 'Failed to load GK zones');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to load GK zones',
      );
    }
  }

  Future<List<GkQuestion>> fetchQuestions({
    required String zone,
    required int categoryId,
    required String level,
  }) async {
    try {
      final Response response = await DioClient.instance.get(
        '/api/gk-master/questions/$zone/$categoryId/$level',
      );

      final data = response.data;

      if (response.statusCode == 200 && data['status'] == true) {
        final List<dynamic> questionList = data['data']?['questions'] ?? [];

        return questionList
            .map((item) => GkQuestion.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }

      throw Exception(data['message'] ?? 'Failed to load GK questions');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to load GK questions',
      );
    }
  }

  Future<Map<String, dynamic>> submitQuiz({
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final Response response = await DioClient.instance.post(
        '/api/gk-master/submit',
        data: {'answers': answers},
      );

      final data = Map<String, dynamic>.from(response.data);

      if (response.statusCode == 200 && data['status'] == true) {
        return data;
      }

      throw Exception(data['message'] ?? 'Failed to submit GK quiz');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data?['message'] ?? 'Failed to submit GK quiz',
      );
    }
  }
}
