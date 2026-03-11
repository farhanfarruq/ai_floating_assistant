// lib/core/utils/logger.dart
import 'package:flutter/foundation.dart';

/// Simple logger utility untuk debugging
class AppLogger {
  static const String _tag = '[AI Assistant]';

  /// Log informasi umum
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('$_tag ℹ️ $message');
    }
  }

  /// Log peringatan
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('$_tag ⚠️ WARNING: $message');
    }
  }

  /// Log error
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('$_tag ❌ ERROR: $message');
      if (error != null) debugPrint('   Error: $error');
      if (stackTrace != null) debugPrint('   Stack: $stackTrace');
    }
  }

  /// Log debug (hanya di debug mode)
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('$_tag 🐛 DEBUG: $message');
    }
  }
}
