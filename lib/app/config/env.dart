// lib/app/config/env.dart

/// Environment configuration
class Env {
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );
  static const bool isProduction = environment == 'prod';
  static const bool isDevelopment = environment == 'dev';
}
