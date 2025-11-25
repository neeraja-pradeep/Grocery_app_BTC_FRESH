import 'package:flutter/foundation.dart';

/// Simple logging utility that respects build mode.
///
/// Logs are only output in debug mode. In release builds, logs are suppressed
/// to avoid performance degradation and prevent sensitive data exposure.
///
/// Usage:
/// ```
/// logger.i('User logged in'); // Info
/// logger.w('Cache miss');     // Warning
/// logger.e('Network error');  // Error
/// logger.d('Debug info');     // Debug
/// ```
class Logger {
  /// Log info level message (only in debug mode)
  void i(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] $message');
    }
  }

  /// Log warning level message (only in debug mode)
  void w(String message) {
    if (kDebugMode) {
      debugPrint('[WARN] $message');
    }
  }

  /// Log error level message (only in debug mode)
  void e(String message) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
    }
    // TODO: In production, report critical errors to Firebase Crashlytics
    // FirebaseCrashlytics.instance.log('[ERROR] $message');
  }

  /// Log debug level message (only in debug mode)
  void d(String message) {
    if (kDebugMode) {
      debugPrint('[DEBUG] $message');
    }
  }
}

/// Global logger instance
final logger = Logger();
