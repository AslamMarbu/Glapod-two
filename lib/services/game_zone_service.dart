import 'package:dio/dio.dart';

import '../models/spelling_quiz_model.dart';
import 'dio_client.dart';

class GameZoneService {
  Future<List<SpellingQuizModel>> getSpellingQuiz(String level) async {
  try {
    final Response response = await DioClient.instance.get(
      "/api/game-zone/spelling-quiz/$level",
    );

    print(response.data);

    if (response.statusCode == 200) {
      final List data = response.data['data'];

      return data
          .map((e) => SpellingQuizModel.fromJson(e))
          .toList();
    }

    return [];
  } on DioException catch (e) {
    throw Exception(e.response?.data['message'] ?? "Failed to load quiz");
  }
}
}