import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Centralized cache for downloaded EdMaster study files.
///
/// Cache age is measured from the file's last-modified timestamp, which is
/// explicitly set when a download completes. Reading a file does not refresh
/// its lifetime.
class FileUtils {
  FileUtils._();

  static const Duration cacheExpiration = Duration(hours: 24);
  static const Duration abandonedPartialExpiration = Duration(hours: 1);
  static const String _cacheDirectoryName = 'edmaster_download_cache';

  static final Map<String, Future<File?>> _activeDownloads = {};
  static final Set<String> _activePartialPaths = <String>{};

  // Reuse the HTTP client so connections can be kept alive and reused.
  // This is initialized lazily, after main() configures HttpOverrides.
  static final http.Client _httpClient = http.Client();

  static bool _isInvalidUrl(String url) =>
      url.trim().isEmpty || url.trim().toLowerCase() == 'null';

  /// Returns the dedicated EdMaster download-cache directory.
  static Future<Directory> getCacheDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'The native file cache is not available on Flutter Web.',
      );
    }

    final supportDirectory = await getApplicationSupportDirectory();
    final directory = Directory(
      '${supportDirectory.path}${Platform.pathSeparator}$_cacheDirectoryName',
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  /// Retained for compatibility with existing callers.
  static Future<String> getLocalPath(String url) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Local file paths are not available on Flutter Web.',
      );
    }

    final directory = await getCacheDirectory();
    final hash = md5.convert(utf8.encode(url)).toString();
    final extension = _safeExtension(url);
    return '${directory.path}${Platform.pathSeparator}$hash.$extension';
  }

  static String _safeExtension(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        final fileName = uri.pathSegments.last;
        final dot = fileName.lastIndexOf('.');
        if (dot >= 0 && dot < fileName.length - 1) {
          final candidate = fileName.substring(dot + 1).toLowerCase();
          if (RegExp(r'^[a-z0-9]{1,10}$').hasMatch(candidate)) {
            return candidate;
          }
        }
      }
    } catch (_) {
      // Use a generic extension for URLs that cannot be parsed.
    }
    return 'file';
  }

  /// Returns a non-empty cache file only if it is less than 24 hours old.
  ///
  /// Expired/invalid files are removed from this application's cache only.
  /// An active download's partial file is never considered a cache entry.
  static Future<File?> getValidCache(String url) async {
    if (kIsWeb || _isInvalidUrl(url)) return null;

    try {
      final file = File(await getLocalPath(url));
      if (!await file.exists()) return null;

      final size = await file.length();
      if (size <= 0) {
        await _deleteFileSafely(file);
        return null;
      }

      final modifiedAt = await file.lastModified();
      final age = DateTime.now().difference(modifiedAt);

      // A timestamp significantly in the future is suspicious; don't reuse it.
      if (age.isNegative || age >= cacheExpiration) {
        debugPrint('CACHE EXPIRED/INVALID => $url');
        await _deleteFileSafely(file);
        return null;
      }

      return file;
    } catch (e) {
      debugPrint('CACHE CHECK ERROR => $e');
      return null;
    }
  }

  /// Downloads a file to a partial path and atomically renames it on success.
  /// Returns a valid cache entry when one already exists.
  static Future<File?> downloadFile(String url) async {
    // Flutter Web cannot create dart:io File objects. The web PDF viewer
    // must fetch PDF bytes directly instead of using this native cache.
    if (kIsWeb) {
      debugPrint('Native file download cache is unavailable on Web => $url');
      return null;
    }

    final cleanUrl = url.trim();
    if (_isInvalidUrl(cleanUrl)) return null;

    final existing = _activeDownloads[cleanUrl];
    if (existing != null) return existing;

    final future = _downloadFileInternal(cleanUrl);
    _activeDownloads[cleanUrl] = future;

    try {
      return await future;
    } finally {
      _activeDownloads.remove(cleanUrl);
    }
  }

  static Future<File?> _downloadFileInternal(String url) async {
    final cachedFile = await getValidCache(url);

    if (cachedFile != null) {
      debugPrint('USING CACHE => $url');
      return cachedFile;
    }

    String? partialPath;

    try {
      final finalPath = await getLocalPath(url);
      final finalFile = File(finalPath);
      final tempFile = File('$finalPath.download');

      partialPath = tempFile.path;
      _activePartialPaths.add(tempFile.path);

      // Remove any incomplete previous download.
      await _deleteFileSafely(tempFile);

      final request = http.Request('GET', Uri.parse(url));

      // Request a PDF response and keep the connection reusable.
      request.headers.addAll({
        'Accept': 'application/pdf,application/octet-stream,*/*',
        'Accept-Encoding': 'identity',
        'User-Agent': 'Mozilla/5.0 EdMaster Android',
        'Connection': 'keep-alive',
      });

      request.persistentConnection = true;

      debugPrint('DOWNLOAD START => $url');

      // Use the shared client instead of creating a new client each time.
      final response = await _httpClient.send(request);

      debugPrint('DOWNLOAD STATUS => ${response.statusCode}');

      if (response.statusCode != HttpStatus.ok) {
        debugPrint('DOWNLOAD FAILED => ${response.statusCode} | $url');

        // Drain the response so the connection can be reused.
        await response.stream.drain<void>();

        await _deleteFileSafely(tempFile);
        return null;
      }

      final expectedSize = response.contentLength;

      // Stream directly to disk. The complete PDF is never loaded into memory.
      final sink = tempFile.openWrite();

      try {
        await response.stream.pipe(sink);
      } catch (_) {
        await sink.close();
        rethrow;
      }

      if (!await tempFile.exists()) {
        debugPrint('DOWNLOAD FILE MISSING => $url');
        return null;
      }

      final downloadedSize = await tempFile.length();

      if (downloadedSize <= 100) {
        debugPrint('DOWNLOAD EMPTY/TOO SMALL => $url');
        await _deleteFileSafely(tempFile);
        return null;
      }

      // Check the response size when the server provides Content-Length.
      if (expectedSize != null &&
          expectedSize > 0 &&
          downloadedSize != expectedSize) {
        debugPrint(
          'DOWNLOAD SIZE MISMATCH => '
          'Expected: $expectedSize, Received: $downloadedSize',
        );

        await _deleteFileSafely(tempFile);
        return null;
      }

      // Check the PDF signature before placing it in the completed cache.
      final header = await tempFile
          .openRead(0, downloadedSize < 1024 ? downloadedSize : 1024)
          .fold<List<int>>(
            <int>[],
            (previous, chunk) => previous..addAll(chunk),
          );

      const signature = <int>[0x25, 0x50, 0x44, 0x46, 0x2D]; // %PDF-

      bool validPdf = false;

      for (var i = 0; i <= header.length - signature.length; i++) {
        var matches = true;

        for (var j = 0; j < signature.length; j++) {
          if (header[i + j] != signature[j]) {
            matches = false;
            break;
          }
        }

        if (matches) {
          validPdf = true;
          break;
        }
      }

      if (!validPdf) {
        debugPrint('DOWNLOAD IS NOT A VALID PDF => $url');
        await _deleteFileSafely(tempFile);
        return null;
      }

      // Replace the old cache only after the new PDF is complete and valid.
      await _deleteFileSafely(finalFile);
      await tempFile.rename(finalPath);

      final completedFile = File(finalPath);
      await completedFile.setLastModified(DateTime.now());

      debugPrint(
        'DOWNLOAD COMPLETE => $url | '
        '$downloadedSize bytes',
      );

      return completedFile;
    } catch (e) {
      debugPrint('DOWNLOAD ERROR => $e | $url');

      if (partialPath != null) {
        await _deleteFileSafely(File(partialPath));
      }

      return null;
    } finally {
      if (partialPath != null) {
        _activePartialPaths.remove(partialPath);
      }
    }
  }

  /// Removes a cache entry that fails a file-type-specific validation, such
  /// as a downloaded textbook whose contents do not start with `%PDF-`.
  static Future<void> deleteCachedFile(String url) async {
    if (kIsWeb || _isInvalidUrl(url)) return;
    try {
      await _deleteFileSafely(File(await getLocalPath(url)));
    } catch (e) {
      debugPrint('CACHE DELETE ERROR => $e');
    }
  }

  /// Safe to call repeatedly. It only visits the dedicated EdMaster cache
  /// directory, never the general temporary directory or other app files.
  ///
  /// Expired complete files are deleted. Abandoned `.download` files are
  /// removed after one hour, except partial files currently being downloaded.
  static Future<void> cleanupExpiredCache() async {
    if (kIsWeb) return;

    try {
      final directory = await getCacheDirectory();
      final now = DateTime.now();

      await for (final entity in directory.list(followLinks: false)) {
        if (entity is! File) continue;

        final path = entity.path;
        if (_activePartialPaths.contains(path)) continue;

        final name = path.split(Platform.pathSeparator).last;
        try {
          final stat = await entity.stat();
          if (stat.type != FileSystemEntityType.file || stat.size <= 0) {
            await _deleteFileSafely(entity);
            continue;
          }

          final age = now.difference(stat.modified);
          if (name.endsWith('.download')) {
            if (age.isNegative || age >= abandonedPartialExpiration) {
              await _deleteFileSafely(entity);
            }
          } else if (age.isNegative || age >= cacheExpiration) {
            await _deleteFileSafely(entity);
          }
        } catch (e) {
          debugPrint('CACHE CLEANUP FILE ERROR ($path) => $e');
        }
      }
      debugPrint('EdMaster expired-cache cleanup completed.');
    } catch (e) {
      // Cleanup must not prevent the app from launching.
      debugPrint('EdMaster cache cleanup error => $e');
    }
  }

  static Future<void> _deleteFileSafely(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } on FileSystemException catch (e) {
      // A file may be locked by the platform/viewer. Leave it in place and
      // let a later cleanup/request retry rather than failing the app.
      debugPrint('Unable to delete cache file ${file.path}: $e');
    } catch (e) {
      debugPrint('Unable to delete cache file ${file.path}: $e');
    }
  }

  static Future<void> testNcertConnection() async {
    final url = Uri.parse('https://ncert.nic.in/textbook/pdf/jess201.pdf');

    final client = HttpClient();

    try {
      debugPrint('NCERT TEST START');

      final request = await client.getUrl(url);
      final response = await request.close();

      debugPrint('NCERT TEST STATUS => ${response.statusCode}');
      debugPrint('NCERT TEST TYPE => ${response.headers.contentType}');

      await response.drain<void>();
    } catch (e) {
      debugPrint('NCERT TEST ERROR => $e');
    } finally {
      client.close();
    }
  }
}
