import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

class Logger {
  Logger._();

  // ============================================================================
  // INTERNAL HELPER
  // ============================================================================

  static void _log(String level, String message, {Object? payload}) {
    if (!kDebugMode) return;

    final formatted =
        '[$level] $message${payload != null ? ' | $payload' : ''}';

    dev.log(
      formatted,
      name: 'APP_LOG',
      level: 0, // you can also use Level.INFO, WARNING etc.
    );
  }

  // ============================================================================
  // STATIC METHODS
  // ============================================================================

  static void info(String message, {Object? data}) =>
      _log('INFO', message, payload: data);

  static void warning(String message, {Object? error}) =>
      _log('WARN', message, payload: error);

  static void error(String message, {Object? error}) =>
      _log('ERROR', message, payload: error);

  static void debug(String message, {Object? data}) =>
      _log('DEBUG', message, payload: data);

  static void performance(String message, {Object? data}) =>
      _log('PERF', message, payload: data);

  // ============================================================================
  // INSTANCE METHODS
  // ============================================================================

  void i(String message) => _log('INFO', message);

  void w(String message) => _log('WARN', message);

  void e(String message) => _log('ERROR', message);

  void d(String message) => _log('DEBUG', message);
}

/// Global logger instance
final logger = Logger._();
