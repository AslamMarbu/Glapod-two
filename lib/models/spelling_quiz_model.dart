class SpellingQuizModel {
  final int id;
  final String option1;
  final String option2;
  final String option3;
  final String option4;
  final String correctAnswer;

  SpellingQuizModel({
    required this.id,
    required this.option1,
    required this.option2,
    required this.option3,
    required this.option4,
    required this.correctAnswer,
  });

  factory SpellingQuizModel.fromJson(Map<String, dynamic> json) {
    return SpellingQuizModel(
      id: json['id'],
      option1: json['option_1'],
      option2: json['option_2'],
      option3: json['option_3'],
      option4: json['option_4'],
      correctAnswer: json['correct_answer'],
    );
  }
}