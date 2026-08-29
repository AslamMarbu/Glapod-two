import 'package:dio/dio.dart';

import '../models/daily_quiz_model.dart';
import 'dio_client.dart';

class DailyQuizService {
  /// Fetch Daily Quiz
  Future<List<DailyQuizModel>> getDailyQuiz() async {
    try {
      final Response response = await DioClient.instance.get(
        "/api/daily-quiz",
      );

      if (response.statusCode == 200) {
        final List data = response.data['data'];

        return data
            .map((e) => DailyQuizModel.fromJson(e))
            .toList();
      }

      return [];
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? "Failed to load Daily Quiz",
      );
    }
  }

  /// Submit Quiz Answers
Future<Map<String, dynamic>> submitDailyQuiz({
  required List<DailyQuizAnswer> answers,
}) async {
  try {
    final Response response = await DioClient.instance.post(
      '/api/daily-quiz/submit',
      data: {
        'answers': answers.map((answer) => answer.toJson()).toList(),
      },
    );

    if (response.statusCode == 200) {
      final responseData = response.data;

      if (responseData is Map<String, dynamic>) {
        final data = responseData['data'];

        if (data is Map<String, dynamic>) {
          return data;
        }

        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }

        throw Exception(
          responseData['message'] ?? 'Invalid submission response',
        );
      }

      throw Exception('Invalid server response');
    }

    throw Exception('Failed to submit quiz');
  } on DioException catch (e) {
    final responseData = e.response?.data;

    if (responseData is Map && responseData['message'] != null) {
      throw Exception(responseData['message'].toString());
    }

    throw Exception(
      e.message ?? 'Quiz submission failed',
    );
  } catch (e) {
    throw Exception(
      e.toString().replaceFirst('Exception: ', ''),
    );
  }
}
}