import 'dart:io';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class FileUtils {
  static Future<String> getLocalPath(String url) async {
    final directory = await getTemporaryDirectory();

    final bytes = utf8.encode(url);
    final hash = md5.convert(bytes).toString();

    String extension = 'file';

    try {
      final uri = Uri.parse(url);

      if (uri.pathSegments.isNotEmpty) {
        final fileName = uri.pathSegments.last;

        if (fileName.contains('.')) {
          extension = fileName.split('.').last;
        }
      }
    } catch (_) {}

    return "${directory.path}/$hash.$extension";
  }

  static Future<File?> getValidCache(String url) async {
    if (url.isEmpty || url == "null") {
      return null;
    }

    try {
      final path = await getLocalPath(url);
      final file = File(path);

      if (!await file.exists()) {
        return null;
      }

      final fileSize = await file.length();

      if (fileSize <= 0) {
        await file.delete();
        return null;
      }

      final lastModified = await file.lastModified();
      final difference = DateTime.now().difference(lastModified);

      if (difference.inHours >= 12) {
        debugPrint("CACHE EXPIRED => $url");

        await file.delete();

        return null;
      }

      return file;
    } catch (e) {
      debugPrint("CACHE CHECK ERROR => $e");
      return null;
    }
  }

  static Future<File?> downloadFile(String url) async {
    if (url.isEmpty || url == "null") {
      return null;
    }

    final cachedFile = await getValidCache(url);

    if (cachedFile != null) {
      debugPrint("USING CACHE => $url");
      return cachedFile;
    }

    final path = await getLocalPath(url);

    final finalFile = File(path);
    final tempFile = File("$path.download");

    http.Client? client;

    try {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      client = http.Client();

      final request = http.Request("GET", Uri.parse(url));

      debugPrint("DOWNLOAD START => $url");

      final response = await client.send(request);

      debugPrint("DOWNLOAD STATUS => ${response.statusCode}");

      if (response.statusCode != 200) {
        debugPrint("DOWNLOAD FAILED => ${response.statusCode} | $url");

        return null;
      }

      final sink = tempFile.openWrite();

      await response.stream.pipe(sink);

      if (!await tempFile.exists()) {
        debugPrint("DOWNLOAD FILE MISSING => $url");
        return null;
      }

      final downloadedSize = await tempFile.length();

      if (downloadedSize <= 0) {
        await tempFile.delete();

        debugPrint("DOWNLOAD EMPTY => $url");

        return null;
      }

      if (await finalFile.exists()) {
        await finalFile.delete();
      }

      await tempFile.rename(path);

      debugPrint("DOWNLOAD COMPLETE => $url | $downloadedSize bytes");

      return File(path);
    } catch (e) {
      debugPrint("DOWNLOAD ERROR => $e | $url");

      try {
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}

      return null;
    } finally {
      client?.close();
    }
  }
}
