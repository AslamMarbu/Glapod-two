import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../utils/file_utils.dart';

class TextbookProvider extends ChangeNotifier {
  final Map<String, bool> _loadingStatus = {};

  // Prevent duplicate downloads for the same textbook URL.
  final Map<String, Future<File?>> _activeDownloads = {};

  bool isLoading(String url) {
    return _loadingStatus[url] ?? false;
  }

  // =========================================================
  // CHECK WHETHER TEXTBOOK FILE IS VALID
  // =========================================================

  Future<bool> isFileValid(String url) async {
    if (_isInvalidUrl(url)) {
      return false;
    }

    try {
      final file = await FileUtils.getValidCache(url);

      if (file == null) {
        return false;
      }

      return await _isValidPdf(file);
    } catch (e) {
      debugPrint('Textbook cache validation error: $e');
      return false;
    }
  }

  // =========================================================
  // GET TEXTBOOK
  // =========================================================

  Future<File?> getBook(String url) async {
    final cleanUrl = url.trim();

    if (_isInvalidUrl(cleanUrl)) {
      debugPrint('Invalid textbook URL: $cleanUrl');
      return null;
    }

    // If already downloading this same textbook,
    // return the existing download instead of starting another.
    final existingDownload = _activeDownloads[cleanUrl];

    if (existingDownload != null) {
      return existingDownload;
    }

    final future = _getBookInternal(cleanUrl);

    _activeDownloads[cleanUrl] = future;

    try {
      return await future;
    } finally {
      _activeDownloads.remove(cleanUrl);
    }
  }

  // =========================================================
  // INTERNAL TEXTBOOK LOADING
  // =========================================================

  Future<File?> _getBookInternal(String url) async {
    _loadingStatus[url] = true;
    notifyListeners();

    try {
      // -------------------------------------------------------
      // FIRST: CHECK EXISTING CACHE
      // -------------------------------------------------------

      debugPrint('Checking textbook cache: $url');

      final cachedFile = await FileUtils.getValidCache(url);

      if (cachedFile != null) {
        final isValid = await _isValidPdf(cachedFile);

        if (isValid) {
          debugPrint('Opening textbook from cache: ${cachedFile.path}');

          return cachedFile;
        }

        debugPrint('Cached textbook is invalid. Downloading again.');
      }

      // -------------------------------------------------------
      // DOWNLOAD WITH RETRIES
      // -------------------------------------------------------

      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          debugPrint('Textbook download attempt $attempt/3: $url');

          final file = await FileUtils.downloadFile(url);

          if (file != null) {
            final isValid = await _isValidPdf(file);

            if (isValid) {
              debugPrint('Textbook downloaded successfully: ${file.path}');

              return file;
            }

            debugPrint('Downloaded textbook is invalid.');
          }
        } catch (e) {
          debugPrint('Textbook attempt $attempt failed: $e');
        }

        // Wait before retrying.
        if (attempt < 3) {
          await Future.delayed(Duration(seconds: attempt));
        }
      }

      debugPrint('Textbook download failed after 3 attempts: $url');

      return null;
    } catch (e, stackTrace) {
      debugPrint('Textbook provider error: $e');

      debugPrint('$stackTrace');

      return null;
    } finally {
      _loadingStatus[url] = false;
      notifyListeners();
    }
  }

  // =========================================================
  // PDF VALIDATION
  // =========================================================

  Future<bool> _isValidPdf(File file) async {
    try {
      if (!await file.exists()) {
        return false;
      }

      final fileSize = await file.length();

      // Reject empty or suspiciously small files.
      if (fileSize <= 100) {
        return false;
      }

      // Check the PDF header.
      final randomAccessFile = await file.open();

      try {
        final header = await randomAccessFile.read(5);

        final headerText = String.fromCharCodes(header);

        if (headerText != '%PDF-') {
          debugPrint('Invalid PDF header: $headerText');

          return false;
        }
      } finally {
        await randomAccessFile.close();
      }

      return true;
    } catch (e) {
      debugPrint('PDF validation error: $e');

      return false;
    }
  }

  // =========================================================
  // URL VALIDATION
  // =========================================================

  bool _isInvalidUrl(String url) {
    return url.isEmpty || url == 'null';
  }
}
