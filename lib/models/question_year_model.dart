class QuestionYearModel {
  final int subjectId;
  final String subjectName;
  final List<YearSetData> years;

  QuestionYearModel({
    required this.subjectId,
    required this.subjectName,
    required this.years
  });

  factory QuestionYearModel.fromJson(Map<String, dynamic> json) {
    // Access the 'data' object first
    var data = json['data'];

    return QuestionYearModel(
      subjectId: data['subject_id'], // Must match the API exactly!
      subjectName: data['subject_name'],
      years: (data['years'] as List)
          .map((i) => YearSetData.fromJson(i))
          .toList(),
    );
  }
}

class YearSetData {
  final String year;
  final int totalSets;

  YearSetData({required this.year, required this.totalSets});

  factory YearSetData.fromJson(Map<String, dynamic> json) {
    return YearSetData(
      year: json['year'],
      totalSets: json['number_of_papers'],
    );
  }
}