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

  // ============================================================================
  // SENTRY RATE LIMITING
  // ============================================================================

  /// Minimum gap between two reports carrying the same message.
  ///
  /// Without this, a repeated condition floods Sentry: the worst offender was
  /// a "socket not connected" warning raised once per product card, so a
  /// single scroll through a category could emit a hundred identical events —
  /// each one building a stack trace (`attachStacktrace: true`) and a network
  /// request, on the UI isolate, while the user was dragging.
  static const Duration _dedupeWindow = Duration(minutes: 5);

  /// Ceiling on reports per [_rateLimitWindow], across all messages. A backstop
  /// for storms of *distinct* messages, which deduping alone cannot catch.
  static const int _maxReportsPerWindow = 20;
  static const Duration _rateLimitWindow = Duration(minutes: 1);

  /// Last time each message was forwarded, used for deduping.
  static final Map<String, DateTime> _lastReportedAt = {};

  /// Guards [_lastReportedAt] against unbounded growth on apps that generate
  /// many distinct messages.
  static const int _maxTrackedMessages = 200;

  static DateTime? _windowStartedAt;
  static int _reportsInWindow = 0;

  /// Whether [message] may be forwarded to Sentry right now.
  static bool _shouldReport(String message) {
    final now = DateTime.now();

    // Per-message dedupe.
    final last = _lastReportedAt[message];
    if (last != null && now.difference(last) < _dedupeWindow) return false;

    // Global rate limit.
    final windowStart = _windowStartedAt;
    if (windowStart == null || now.difference(windowStart) >= _rateLimitWindow) {
      _windowStartedAt = now;
      _reportsInWindow = 0;
    }
    if (_reportsInWindow >= _maxReportsPerWindow) return false;
    _reportsInWindow++;

    if (_lastReportedAt.length >= _maxTrackedMessages) _lastReportedAt.clear();
    _lastReportedAt[message] = now;
    return true;
  }

  /// Clears rate-limiter state. Test-only.
  @visibleForTesting
  static void resetSentryRateLimit() {
    _lastReportedAt.clear();
    _windowStartedAt = null;
    _reportsInWindow = 0;
  }

  /// Forward an error to Sentry when a DSN is configured. Fire-and-forget;
  /// the SDK no-ops when uninitialized so this is safe to call always.
  ///
  /// Deduped and rate limited — see [_shouldReport]. Note this runs in release
  /// builds even though [_log] does not, so an unthrottled caller in a hot
  /// path costs real work in production and nothing in development.
  static void _reportToSentry(
    String message, {
    Object? error,
    SentryLevel level = SentryLevel.error,
  }) {
    if (!AppConfig.isSentryEnabled) return;
    if (!_shouldReport(message)) return;

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
