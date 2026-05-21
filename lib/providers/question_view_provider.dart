import 'package:flutter/material.dart';

class QuestionViewProvider with ChangeNotifier {
  List<dynamic> _qaList = [];
  int _currentIndex = 0;
  bool _showAnswer = false; // Persistent state

  // Getters
  List<dynamic> get qaList => _qaList;
  int get currentIndex => _currentIndex;
  bool get showAnswer => _showAnswer;
  dynamic get currentQA => _qaList.isNotEmpty ? _qaList[_currentIndex] : null;

  void setInitialData(List<dynamic> list, int index) {
    _qaList = list;
    _currentIndex = index;
    _showAnswer = false; // Always start with answer hidden for a new set
    notifyListeners();   // This forces the UI to catch the new data immediately
  }
  void disposeData() {
    _qaList = [];
    _currentIndex = 0;
    _showAnswer = false;
    // No notifyListeners() needed here if you call this on dispose
  }

  void nextQuestion() {
    if (_currentIndex < _qaList.length - 1) {
      _currentIndex++;
      // Persistence: Removed _showAnswer = false;
      notifyListeners();
    }
  }

  void previousQuestion() {
    if (_currentIndex > 0) {
      _currentIndex--;
      // Persistence: Removed _showAnswer = false;
      notifyListeners();
    }
  }

  void toggleAnswer(bool value) {
    _showAnswer = value;
    notifyListeners();
  }

  void updateBookmark(bool isBookmarked) {
    if (_qaList.isNotEmpty) {
      _qaList[_currentIndex]['bookmark'] = isBookmarked;
      notifyListeners();
    }
  }

  String cleanHtml(String? text) {
    if (text == null) return "";
    // Removes HTML tags and handles basic whitespace
    return text.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), ' ').trim();
  }
}