import 'package:flutter/foundation.dart';

@immutable
class DailyQuizModel {
  final int id;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;

  const DailyQuizModel({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
  });

  factory DailyQuizModel.fromJson(Map<String, dynamic> json) {
    return DailyQuizModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      question: json['question']?.toString() ?? '',
      optionA: json['option_a']?.toString() ?? '',
      optionB: json['option_b']?.toString() ?? '',
      optionC: json['option_c']?.toString() ?? '',
      optionD: json['option_d']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
    };
  }
}

@immutable
class DailyQuizAnswer {
  final int questionId;
  final String? selectedAnswer;

  const DailyQuizAnswer({
    required this.questionId,
    this.selectedAnswer,
  });

  Map<String, dynamic> toJson() {
    return {
      'question_id': questionId,
      'selected_answer': selectedAnswer,
    };
  }
}