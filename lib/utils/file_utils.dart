import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class FileUtils {
  /// Generates a unique path based on MD5 hash of the URL
  static Future<String> getLocalPath(String url) async {
    // Note: If you want these files to survive app closes better on some phones,
    // consider changing getTemporaryDirectory() to getApplicationDocumentsDirectory()
    final directory = await getTemporaryDirectory();
    final bytes = utf8.encode(url);
    final hash = md5.convert(bytes).toString();
    final extension = url.split('.').last.split('?').first;
    return "${directory.path}/$hash.$extension";
  }

  /// 🔹 Logic: Checks if file exists and is < 12 hours old
  static Future<File?> getValidCache(String url) async {
    if (url.isEmpty || url == "null") return null;
    final path = await getLocalPath(url);
    final file = File(path);

    if (await file.exists()) {
      final lastModified = await file.lastModified();
      final difference = DateTime.now().difference(lastModified);

      // 🔹 CHANGED: Check if the difference is 12 hours or more
      if (difference.inHours >= 12) {
        await file.delete();
        return null;
      }
      return file;
    }
    return null;
  }

  /// 🔹 Action: Downloads or retrieves from cache
  static Future<File?> downloadFile(String url) async {
    final path = await getLocalPath(url);

    // This will now use the 12-hour rule defined above
    final cachedFile = await getValidCache(url);
    if (cachedFile != null) return cachedFile;

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final file = File(path);
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (e) {
      print("Download error: $e");
    }
    return null;
  }
}