import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
class DeviceService {
  static Future<String?> getUniqueId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (kIsWeb) {
      WebBrowserInfo webBrowserInfo = await deviceInfo.webBrowserInfo;
      // Since there is no hardware ID on web, userAgent + vendor is a common substitute
      // or use browserFingerprint if you use a specific package for that.
      return "${webBrowserInfo.userAgent}_${webBrowserInfo.vendor}";
    }else if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      // 'id' is the hardware/build ID; 'serialNumber' is often restricted.
      // For many, 'id' or a combination of fields is used.
      return androidInfo.id;
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      // identifierForVendor is the standard unique ID for iOS
      return iosInfo.identifierForVendor;
    }
    return null;
  }
}