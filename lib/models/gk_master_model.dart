class GkZone {
  final String key;
  final String name;

  const GkZone({required this.key, required this.name});

  factory GkZone.fromJson(Map<String, dynamic> json) {
    return GkZone(
      key: json['key']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }
}

class GkCategory {
  final int id;
  final String name;
  final int totalQuestions;

  const GkCategory({
    required this.id,
    required this.name,
    required this.totalQuestions,
  });

  factory GkCategory.fromJson(Map<String, dynamic> json) {
    return GkCategory(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      totalQuestions:
          int.tryParse(json['total_questions']?.toString() ?? '0') ?? 0,
    );
  }
}

class GkQuestion {
  final int id;
  final String question;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;

  // NEW
  final String correctAnswer;
  final String answerExplanation;

  const GkQuestion({
    required this.id,
    required this.question,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,

    // NEW
    required this.correctAnswer,
    required this.answerExplanation,
  });

  factory GkQuestion.fromJson(Map<String, dynamic> json) {
    return GkQuestion(
      id: int.tryParse(json['id'].toString()) ?? 0,
      question: json['question']?.toString() ?? '',
      optionA: json['option_a']?.toString() ?? '',
      optionB: json['option_b']?.toString() ?? '',
      optionC: json['option_c']?.toString() ?? '',
      optionD: json['option_d']?.toString() ?? '',

      // NEW
      correctAnswer: json['correct_answer']?.toString() ?? '',
      answerExplanation: json['answer_explanation']?.toString() ?? '',
    );
  }

  Map<String, String> get options {
    return {
      'option_a': optionA,
      'option_b': optionB,
      'option_c': optionC,
      'option_d': optionD,
    };
  }
}
