import 'dart:convert';
import 'package:flutter/foundation.dart';

class AppLogger {
  static void log(dynamic data, {String tag = "DEBUG"}) {
    // 1. If data is null
    if (data == null) {
      debugPrint("[$tag]: Value is null");
      return;
    }

    // 2. Handle JSON Maps or Lists
    if (data is Map || data is List) {
      try {
        const encoder = JsonEncoder.withIndent('  '); // Makes it pretty
        debugPrint("[$tag] (JSON): ${encoder.convert(data)}");
      } catch (e) {
        debugPrint("[$tag]: $data");
      }
    }
    // 3. Handle Strings that might be JSON strings
    else if (data is String) {
      try {
        final decoded = jsonDecode(data);
        const encoder = JsonEncoder.withIndent('  ');
        debugPrint("[$tag] (Parsed JSON String): ${encoder.convert(decoded)}");
      } catch (e) {
        // It's just a normal string, print as is
        debugPrint("[$tag]: $data");
      }
    }
    // 4. Handle everything else (int, bool, etc.)
    else {
      debugPrint("[$tag]: ${data.toString()}");
    }
  }
}