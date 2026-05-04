import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb; // Import kIsWeb
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  static Future<String> getDeviceId() async {
    // 1. ALWAYS check kIsWeb first
    String? webId='';
    if (kIsWeb) {
      final random = Random();
      final now = DateTime.now().millisecondsSinceEpoch;
      webId = "web_${now}_${random.nextInt(1000000)}";
    }

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // Unique ID for Android
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? "iOS_Device";
      }
    } catch (e) {
      return "Error_Device";
    }

    return "Unknown_Device";
  }
}