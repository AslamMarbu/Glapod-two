import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'package:Edmaster/storage/local_storage_service.dart';

class ProfileImageCacheService {
  /// Get the currently cached profile image.
  static Future<File?> getLocalImage() async {
    try {
      final path = await LocalStorageService.getProfileImagePath();

      if (path == null || path.isEmpty) {
        return null;
      }

      final file = File(path);

      if (await file.exists()) {
        return file;
      }

      return null;
    } catch (e) {
      print('GET PROFILE CACHE ERROR: $e');
      return null;
    }
  }

  static Future<File?> saveImageBytes(Uint8List bytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();

      final profileDirectory = Directory('${directory.path}/profile_cache');

      if (!await profileDirectory.exists()) {
        await profileDirectory.create(recursive: true);
      }

      // Remember the old image
      final oldPath = await LocalStorageService.getProfileImagePath();

      // Create a NEW filename every time
      final fileName =
          'profile_image_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final newFile = File('${profileDirectory.path}/$fileName');

      // Save the new image
      await newFile.writeAsBytes(bytes, flush: true);

      // Save the new path
      await LocalStorageService.saveProfileImagePath(newFile.path);

      // Delete old image
      if (oldPath != null && oldPath.isNotEmpty && oldPath != newFile.path) {
        try {
          final oldFile = File(oldPath);

          if (await oldFile.exists()) {
            await oldFile.delete();
          }
        } catch (e) {
          print('Could not delete old profile image: $e');
        }
      }

      return newFile;
    } catch (e) {
      print('Save profile image error: $e');
      return null;
    }
  }

  /// Download profile image from server and cache it locally.
  static Future<File?> downloadAndCache(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) {
        return null;
      }

      final uri = Uri.parse(imageUrl);

      final client = HttpClient();

      try {
        final request = await client.getUrl(uri);
        final response = await request.close();

        if (response.statusCode != 200) {
          return null;
        }

        final bytes = await response.fold<List<int>>(
          <int>[],
          (previous, element) => previous..addAll(element),
        );

        if (bytes.isEmpty) {
          return null;
        }

        return await saveImageBytes(Uint8List.fromList(bytes));
      } finally {
        client.close();
      }
    } catch (e) {
      print('DOWNLOAD PROFILE IMAGE ERROR: $e');

      return null;
    }
  }

  /// Remove cached profile image.
  static Future<void> clear() async {
    try {
      final path = await LocalStorageService.getProfileImagePath();

      if (path != null && path.isNotEmpty) {
        final file = File(path);

        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      print('DELETE PROFILE CACHE ERROR: $e');
    }

    await LocalStorageService.clearProfileImageCache();
  }
}
