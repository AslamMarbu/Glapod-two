import 'dart:io';

import 'package:flutter/material.dart';

import '../utils/file_utils.dart';

class TextbookProvider extends ChangeNotifier {
  final Map<String, bool> _loadingStatus = {};

  bool isLoading(String url) => _loadingStatus[url] ?? false;

  Future<bool> isFileValid(String url) async {
    if (url.isEmpty || url == 'null') {
      return false;
    }

    final file = await FileUtils.getValidCache(url);

    return file != null;
  }

  Future<File?> getBook(String url) async {
    if (url.isEmpty || url == 'null') {
      return null;
    }

    _loadingStatus[url] = true;
    notifyListeners();

    try {
      final file = await FileUtils.downloadFile(url);

      if (file == null) {
        debugPrint('Textbook download failed => $url');
      }

      return file;
    } catch (e) {
      debugPrint('Textbook download error => $e');

      return null;
    } finally {
      _loadingStatus[url] = false;
      notifyListeners();
    }
  }
}
