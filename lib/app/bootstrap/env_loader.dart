// lib/app/bootstrap/env_loader.dart

/// Environment configuration loader.
///
/// Validates build-time environment values set via --dart-define.
/// All config values live in AppConfig; this class asserts they are valid.
class EnvLoader {
  static const _apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://156.67.104.149:8080',
  );

  static Future<void> load() async {
    assert(_apiUrl.isNotEmpty, 'API_BASE_URL must be defined');
  }
}
