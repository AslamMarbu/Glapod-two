import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/file_utils.dart';

class TextbookProvider extends ChangeNotifier {
  final Map<String, bool> _loadingStatus = {};
  bool isLoading(String url) => _loadingStatus[url] ?? false;

  Future<bool> isFileValid(String url) async => (await FileUtils.getValidCache(url)) != null;

  Future<File?> getBook(String url) async {
    if (url.isEmpty) return null;
    _loadingStatus[url] = true;
    notifyListeners();

    try {
      return await FileUtils.downloadFile(url);
    } finally {
      _loadingStatus[url] = false;
      notifyListeners();
    }
  }
}