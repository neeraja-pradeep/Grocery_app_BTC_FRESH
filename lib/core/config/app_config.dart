/// Centralized configuration for all backend URLs and app settings
///
/// Pass build-time values via --dart-define:
///   IS_PRODUCTION=true
///   API_BASE_URL=https://your-prod-server.com
///   SENTRY_DSN=https://PUBLIC_KEY@oORG.ingest.sentry.io/PROJECT_ID
///
/// Example release command:
///   flutter build apk --dart-define=IS_PRODUCTION=true \
///                     --dart-define=API_BASE_URL=https://prod-server.com \
///                     --dart-define=SENTRY_DSN=https://...@sentry.io/...
class AppConfig {
  AppConfig._();

  // ============================================================================
  // ENVIRONMENT CONFIGURATION
  // ============================================================================

  /// Whether this is a production build.
  /// Set via --dart-define=IS_PRODUCTION=true in CI/CD release pipeline.
  static const bool isProduction = bool.fromEnvironment(
    'IS_PRODUCTION',
    defaultValue: false,
  );

  static const bool isDevelopment = !isProduction;

  // ============================================================================
  // API BASE URLS
  // ============================================================================

  /// Main backend API server.
  /// Override for production: --dart-define=API_BASE_URL=https://prod-server.com
  /// WARNING: default value uses HTTP — only acceptable for local dev.
  /// Production builds MUST pass an HTTPS URL via --dart-define.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://156.67.104.149:8080',
  );

  /// API base URL with trailing slash (for some endpoints that need it)
  static const String apiBaseUrlWithSlash = '$apiBaseUrl/';

  /// WebSocket server URL (if different from API server)
  static const String webSocketUrl = apiBaseUrl;

  // ============================================================================
  // CDN / MEDIA URLS
  // ============================================================================

  /// CDN base URL for images and media files
  static const String cdnBaseUrl = 'https://grocery-application.b-cdn.net';

  /// Internal server base URL (used for image URL conversion)
  static const String internalServerBase = apiBaseUrl;

  // ============================================================================
  // APP INFORMATION
  // ============================================================================

  static const String appName = 'BTC Fresh';
  static const String appVersion = '1.0.0';

  // ============================================================================
  // OBSERVABILITY / CRASH REPORTING
  // ============================================================================

  /// Sentry DSN. The committed default points at the BTC Fresh project so
  /// every build (dev + production) reports to Sentry out of the box. The
  /// build can still override it with `--dart-define=SENTRY_DSN=...` (e.g.
  /// to send to a separate project per environment, or to disable by
  /// passing an empty string).
  static const String sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue:
        'https://5c89b3671403f2acbd6f6b81c093be5f@o4510509677608960.ingest.us.sentry.io/4511427534585856',
  );

  /// `true` when a DSN is provided. Used by bootstrap and Logger to decide
  /// whether Sentry events should be sent.
  static bool get isSentryEnabled => sentryDsn.isNotEmpty;

  // ============================================================================
  // API TIMEOUT CONFIGURATION
  // ============================================================================

  /// Connection timeout — 10 seconds as per QA Prompt 5 spec.
  static const Duration connectTimeout = Duration(seconds: 10);

  /// Receive timeout — 10 seconds as per QA Prompt 5 spec.
  static const Duration receiveTimeout = Duration(seconds: 10);

  /// Send timeout — 10 seconds as per QA Prompt 5 spec.
  static const Duration sendTimeout = Duration(seconds: 10);

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Convert internal server URLs to CDN URLs for images
  static String convertToCdnUrl(String url) {
    if (url.isEmpty) return url;

    // Already a CDN URL
    if (url.startsWith(cdnBaseUrl)) {
      return url;
    }

    // Already has HTTPS protocol (external URL)
    if (url.startsWith('https://') && !url.startsWith(internalServerBase)) {
      return url;
    }

    // Internal server URL - convert to CDN
    if (url.startsWith(internalServerBase)) {
      return url.replaceFirst(internalServerBase, cdnBaseUrl);
    }

    // Relative URL - add CDN base
    if (url.startsWith('/')) {
      return '$cdnBaseUrl$url';
    }

    // No protocol - add HTTPS and CDN base
    return '$cdnBaseUrl/$url';
  }

  /// Ensure URL has HTTPS protocol
  static String ensureHttps(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return 'https://$url';
  }

  /// Get full API URL by appending path to base URL
  static String getApiUrl(String path) {
    if (path.startsWith('/')) return '$apiBaseUrl$path';
    return '$apiBaseUrl/$path';
  }
}
