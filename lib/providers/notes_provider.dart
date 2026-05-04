import 'dart:io';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/student_service.dart';
import '../utils/file_utils.dart'; // 🔹 Import your existing FileUtils

class NotesProvider with ChangeNotifier {
  List<dynamic> _notes = [];
  bool _isLoading = true;
  Map<int, bool> _downloadingStatus = {};

  List<dynamic> get notes => _notes;
  bool get isLoading => _isLoading;
  Map<int, bool> get downloadingStatus => _downloadingStatus;

  Future<void> fetchNotes(dynamic chapterId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _notes = await StudentService.fetchNotes(chapterId);
    } catch (e) {
      _notes = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔹 Standardized Download Logic using FileUtils
  Future<File?> downloadFile(dynamic note) async {
    final String url = note['note_url'];
    final int id = note['id'];

    if (url.isEmpty || url == "null") return null;

    _downloadingStatus[id] = true;
    notifyListeners();

    try {
      // Use FileUtils: Checks if exists -> Downloads if not -> Returns local path
      final String localPath = await FileUtils.downloadAndSave(url);

      return File(localPath);
    } catch (e) {
      debugPrint("Download Error: $e");
      return null;
    } finally {
      _downloadingStatus[id] = false;
      notifyListeners();
    }
  }

  IconData getFaIcon(String iconClass) {
    switch (iconClass) {
      case 'fas fa-file-pdf': return FontAwesomeIcons.filePdf;
      case 'fas fa-image': return FontAwesomeIcons.fileImage;
      case 'fas fa-video':
      case 'fas fa-file-video': return FontAwesomeIcons.fileVideo;
      case 'fas fa-file-powerpoint': return FontAwesomeIcons.filePowerpoint;
      default: return FontAwesomeIcons.fileLines;
    }
  }

  Color getIconColor(String type) {
    switch (type.toUpperCase()) {
      case 'PDF': return Colors.red.shade700;
      case 'IMAGE': return Colors.green.shade700;
      case 'VIDEO': return Colors.blue.shade700;
      default: return Colors.orange.shade700;
    }
  }
}