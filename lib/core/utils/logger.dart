import 'package:flutter/foundation.dart';

/// Simple logging utility
class Logger {
  void i(String message) => debugPrint('[INFO] $message');
  void w(String message) => debugPrint('[WARN] $message');
  void e(String message) => debugPrint('[ERROR] $message');
  void d(String message) => debugPrint('[DEBUG] $message');
}

final logger = Logger();
