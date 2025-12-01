// lib/core/utils/logger.dart

import 'package:flutter/foundation.dart';

/// Log levels for controlling output verbosity
enum LogLevel {
  debug(0),
  info(1),
  warning(2),
  error(3);

  const LogLevel(this.value);
  final int value;
}

/// Enhanced logger utility for debugging and monitoring
class Logger {
  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.warning;

  /// Set the minimum log level to display
  static void setMinLevel(LogLevel level) {
    _minLevel = level;
  }

  /// Debug messages - detailed information for debugging
  static void debug(String message, {Map<String, dynamic>? data}) {
    if (_shouldLog(LogLevel.debug)) {
      _log('🐛 DEBUG', message, data);
    }
  }

  /// Info messages - general information about app flow
  static void info(String message, {Map<String, dynamic>? data}) {
    if (_shouldLog(LogLevel.info)) {
      _log('ℹ️ INFO', message, data);
    }
  }

  /// Warning messages - potentially harmful situations
  static void warning(
    String message, {
    Object? error,
    Map<String, dynamic>? data,
  }) {
    if (_shouldLog(LogLevel.warning)) {
      _log('⚠️ WARNING', message, data);
      if (error != null) {
        _log('⚠️ WARNING', '  └─ Error: $error', null);
      }
    }
  }

  /// Error messages - error events that might still allow the app to continue
  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    if (_shouldLog(LogLevel.error)) {
      _log('❌ ERROR', message, data);
      if (error != null) {
        _log('❌ ERROR', '  ├─ Error: $error', null);
      }
      if (stackTrace != null && kDebugMode) {
        _log('❌ ERROR', '  └─ StackTrace:', null);
        final frames = stackTrace.toString().split('\n').take(5);
        for (final frame in frames) {
          if (frame.trim().isNotEmpty) {
            _log('❌ ERROR', '     $frame', null);
          }
        }
      }
    }
  }

  /// Internal method to format and output log messages
  static void _log(String prefix, String message, Map<String, dynamic>? data) {
    // final timestamp = DateTime.now().toIso8601String().substring(
    //   11,
    //   23,
    // ); // HH:mm:ss.SSS

    // Use debugPrint in debug mode for better IDE integration
    if (kDebugMode) {
      // debugPrint('[$timestamp] $prefix: $message');
      if (data != null && data.isNotEmpty) {
        // debugPrint('  └─ Data: ${_formatData(data)}');
      }
    } else {
      // In production, only log errors and warnings to system log
      if (prefix.contains('ERROR') || prefix.contains('WARNING')) {
        // Use debugPrint even in production for critical logs
        // as it's safer and can be controlled by Flutter framework
        // debugPrint('[$timestamp] $prefix: $message');
        if (data != null && data.isNotEmpty) {
          // debugPrint('  └─ Data: ${_formatData(data)}');
        }
      }
    }
  }

  /// Format data map for readable output
  // static String _formatData(Map<String, dynamic> data) {
  //   final entries = data.entries.map((e) => '${e.key}: ${e.value}').join(', ');
  //   return '{$entries}';
  // }

  /// Check if a log level should be output
  static bool _shouldLog(LogLevel level) {
    return level.value >= _minLevel.value;
  }

  /// Convenience method for performance logging
  static void performance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? data,
  }) {
    final perfData = {
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      ...?data,
    };
    info(
      'Performance: $operation took ${duration.inMilliseconds}ms',
      data: perfData,
    );
  }

  /// Convenience method for API logging
  static void api(
    String method,
    String endpoint, {
    int? statusCode,
    Duration? duration,
  }) {
    final apiData = {
      'method': method,
      'endpoint': endpoint,
      if (statusCode != null) 'status': statusCode,
      if (duration != null) 'duration_ms': duration.inMilliseconds,
    };
    info('API: $method $endpoint', data: apiData);
  }
}
