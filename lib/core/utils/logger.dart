import 'package:flutter/foundation.dart';

class Logger {
  static bool get isEnabled => kDebugMode;

  static void success(String message) {
    if (isEnabled) {
      debugPrint('\x1B[32m✅ $message\x1B[0m'); // Green
    }
  }

  static void error(String message) {
    if (isEnabled) {
      debugPrint('\x1B[31m❌ $message\x1B[0m'); // Red
    }
  }

  static void warning(String message) {
    if (isEnabled) {
      debugPrint('\x1B[33m⚠️ $message\x1B[0m'); // Yellow
    }
  }

  static void info(String message) {
    if (isEnabled) {
      debugPrint('\x1B[37mℹ️ $message\x1B[0m'); // White
    }
  }
}
