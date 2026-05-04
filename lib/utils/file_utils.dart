import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class FileUtils {
  static Future<String> getLocalPath(String url) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = url.split('/').last;
    return "${directory.path}/$fileName";
  }

  static Future<bool> fileExists(String url) async {
    final path = await getLocalPath(url);
    return File(path).exists();
  }

  static Future<String> downloadAndSave(String url) async {
    final path = await getLocalPath(url);
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final file = File(path);
      await file.writeAsBytes(response.bodyBytes);
      return path;
    } else {
      throw Exception("Failed to download PDF");
    }
  }
}