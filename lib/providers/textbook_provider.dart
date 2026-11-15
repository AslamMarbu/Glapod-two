import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../utils/file_utils.dart';

class TextbookProvider extends ChangeNotifier {
  final Map<String, bool> _loadingStatus = {};
  final Map<String, Future<File?>> _activeDownloads = {};

  bool isLoading(String url) => _loadingStatus[url] ?? false;

  Future<bool> isFileValid(String url) async {
    // Browser builds use remote URLs/bytes, not dart:io File cache entries.
    if (kIsWeb || _isInvalidUrl(url)) return false;

    try {
      final file = await FileUtils.getValidCache(url);
      if (file == null) return false;

      final validPdf = await _isValidPdf(file);
      if (!validPdf) {
        await FileUtils.deleteCachedFile(url);
      }
      return validPdf;
    } catch (e) {
      debugPrint('Textbook cache validation error: $e');
      return false;
    }
  }

  Future<File?> getBook(String url) async {
    // TextbookListingPage bypasses this native-file API on web.
    if (kIsWeb) {
      debugPrint(
        'TextbookProvider.getBook is native-only; use the URL on web.',
      );
      return null;
    }

    final cleanUrl = url.trim();
    if (_isInvalidUrl(cleanUrl)) {
      debugPrint('Invalid textbook URL: $cleanUrl');
      return null;
    }

    final existing = _activeDownloads[cleanUrl];
    if (existing != null) return existing;

    final future = _getBookInternal(cleanUrl);
    _activeDownloads[cleanUrl] = future;

    try {
      return await future;
    } finally {
      _activeDownloads.remove(cleanUrl);
    }
  }

  Future<File?> _getBookInternal(String url) async {
    _loadingStatus[url] = true;
    notifyListeners();

    try {
      // First check the 24-hour cache.
      final cachedFile = await FileUtils.getValidCache(url);

      if (cachedFile != null) {
        if (await _isValidPdf(cachedFile)) {
          debugPrint('Opening textbook from cache: ${cachedFile.path}');
          return cachedFile;
        }

        debugPrint('Invalid cached PDF. Removing it.');
        await FileUtils.deleteCachedFile(url);
      }

      // First download attempt.
      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          debugPrint('Textbook download attempt $attempt/2: $url');

          final file = await FileUtils.downloadFile(url);

          if (file != null && await _isValidPdf(file)) {
            debugPrint('Textbook downloaded successfully: ${file.path}');
            return file;
          }

          if (file != null) {
            debugPrint('Invalid downloaded PDF. Removing it.');
            await FileUtils.deleteCachedFile(url);
          }
        } catch (e) {
          debugPrint('Textbook download attempt $attempt failed: $e');
        }

        // Only a short delay before the final retry.
        if (attempt == 1) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }

      debugPrint('Textbook download failed: $url');
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

  Future<bool> _isValidPdf(File file) async {
    try {
      if (!await file.exists()) return false;

      final length = await file.length();
      if (length <= 100) return false;

      final header = await file
          .openRead(0, length < 1024 ? length : 1024)
          .fold<List<int>>(
            <int>[],
            (previous, chunk) => previous..addAll(chunk),
          );

      const signature = <int>[0x25, 0x50, 0x44, 0x46, 0x2D]; // %PDF-

      for (var i = 0; i <= header.length - signature.length; i++) {
        var matches = true;

        for (var j = 0; j < signature.length; j++) {
          if (header[i + j] != signature[j]) {
            matches = false;
            break;
          }
        }

        if (matches) return true;
      }

      debugPrint('Invalid PDF header: ${file.path}');
      return false;
    } catch (e) {
      debugPrint('PDF validation error: $e');
      return false;
    }
  }

  bool _isInvalidUrl(String url) =>
      url.trim().isEmpty || url.trim().toLowerCase() == 'null';
}
