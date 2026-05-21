import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;

class DeviceService {
  static Future<String> getDeviceId() async {
    // 1. Web Logic: Get Public IP
    if (kIsWeb) {
      try {
        // We use a public service to get the external IP address
        final response = await http.get(Uri.parse('https://api.ipify.org'));
        if (response.statusCode == 200) {
          return "web_ips_${response.body}";
        }
      } catch (e) {
        return "web_ip_unknown";
      }
    }

    // 2. Mobile Logic: Get Stable Hardware IDs
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

        // 'id' is the hardware/build ID.
        // For even higher persistence on Android, many developers use
        // the 'android_id' via the 'android_id' package.
        return "android_${androidInfo.id}";
      }

      if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await deviceInfo.iosInfo;

        // identifierForVendor is the standard for iOS.
        // Note: This changes if ALL apps from the same vendor are uninstalled.
        return "ios_${iosInfo.identifierForVendor ?? 'unknown'}";
      }
    } catch (e) {
      return "device_error_${DateTime.now().millisecondsSinceEpoch}";
    }

    return "unknown_platform";
  }
}