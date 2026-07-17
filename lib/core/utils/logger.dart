import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../config/app_config.dart';

class Logger {
  Logger._();

  // ============================================================================
  // INTERNAL HELPERS
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

  /// Forward an error to Sentry when a DSN is configured. Fire-and-forget;
  /// the SDK no-ops when uninitialized so this is safe to call always.
  static void _reportToSentry(
    String message, {
    Object? error,
    SentryLevel level = SentryLevel.error,
  }) {
    if (!AppConfig.isSentryEnabled) return;
    if (error is Object) {
      Sentry.captureException(
        error,
        stackTrace: error is Error ? error.stackTrace : null,
        hint: Hint.withMap({'message': message}),
      );
    } else {
      Sentry.captureMessage(message, level: level);
    }
  }

  // ============================================================================
  // STATIC METHODS
  // ============================================================================

  static void info(String message, {Object? data}) =>
      _log('INFO', message, payload: data);

  static void warning(String message, {Object? error}) {
    _log('WARN', message, payload: error);
    _reportToSentry(message, error: error, level: SentryLevel.warning);
  }

  static void error(String message, {Object? error}) {
    _log('ERROR', message, payload: error);
    _reportToSentry(message, error: error);
  }

  static void debug(String message, {Object? data}) =>
      _log('DEBUG', message, payload: data);

  static void performance(String message, {Object? data}) =>
      _log('PERF', message, payload: data);

  // ============================================================================
  // INSTANCE METHODS
  // ============================================================================

  void i(String message) => _log('INFO', message);

  void w(String message) {
    _log('WARN', message);
    _reportToSentry(message, level: SentryLevel.warning);
  }

  void e(String message) {
    _log('ERROR', message);
    _reportToSentry(message);
  }

  void d(String message) => _log('DEBUG', message);
}

/// Global logger instance
final logger = Logger._();
