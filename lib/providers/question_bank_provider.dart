import 'package:flutter/material.dart';
import '../services/student_service.dart';

class QuestionBankProvider with ChangeNotifier {
  bool _isLoading = false;
  List<dynamic> _chapterList = [];
  List<dynamic> _markList = [];

  bool get isLoading => _isLoading;
  List<dynamic> get chapterList => _chapterList;
  List<dynamic> get markList => _markList;

  /// Fetches both tabs' initial data
  Future<void> fetchInitialData(String subjectId, String classId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final chapRes = await StudentService.getChaptersList(subjectId, classId);
      final markRes = await StudentService.getQuestionMarkList(subjectId, classId);

      // Filter: only show items with question_count > 0
      _chapterList = (chapRes['sub_list'] as List? ?? []).where((item) {
        return (item['question_count'] ?? 0) > 0;
      }).toList();

      _markList = (markRes['sub_list'] as List? ?? []).where((item) {
        return (item['question_count'] ?? 0) > 0;
      }).toList();

    } catch (e) {
      debugPrint("Error fetching Q-Bank data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches the actual Q&A list for the Detail View
  Future<List<dynamic>?> fetchQuestionSet({
    required bool isChapter,
    required String subjectId,
    required String classId,
    required dynamic item,
  }) async {
    try {
      Map<String, dynamic> response;
      if (isChapter) {
        response = await StudentService.getQuestionsByChapter(
          subjectId, classId, item['id'].toString(),
        );
      } else {
        response = await StudentService.getQuestionsByMark(
          subjectId, classId, item['mark'].toString(),
        );
      }

      if (response['status'] == true && response['question_bank'] != null) {
        return response['question_bank'] as List;
      }
    } catch (e) {
      debugPrint("Error fetching Q-set: $e");
    }
    return null;
  }
}