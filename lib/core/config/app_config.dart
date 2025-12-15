/// Centralized configuration for all backend URLs and app settings
///
/// This file contains all API endpoints, CDN URLs, and environment configurations.
/// Update this file when changing servers or environments.
class AppConfig {
  AppConfig._();

  // ============================================================================
  // ENVIRONMENT CONFIGURATION
  // ============================================================================

  /// Current environment mode
  static const bool isProduction = false;
  static const bool isDevelopment = true;

  // ============================================================================
  // API BASE URLS
  // ============================================================================

  /// Main backend API server
  /// This is used for all API requests (auth, products, orders, etc.)
  static const String apiBaseUrl = 'http://156.67.104.149:8080';

  /// API base URL with trailing slash (for some endpoints that need it)
  static const String apiBaseUrlWithSlash = '$apiBaseUrl/';

  /// WebSocket server URL (if different from API server)
  static const String webSocketUrl = apiBaseUrl;

  // ============================================================================
  // CDN / MEDIA URLS
  // ============================================================================

  /// CDN base URL for images and media files
  /// This is where product images, category images, etc. are hosted
  static const String cdnBaseUrl = 'https://grocery-application.b-cdn.net';

  /// Internal server base URL (used for image URL conversion)
  /// Images from this URL are converted to CDN URLs for better performance
  static const String internalServerBase = apiBaseUrl;

  // ============================================================================
  // APP INFORMATION
  // ============================================================================

  /// Application name
  static const String appName = 'BTC Fresh';

  /// Application version
  static const String appVersion = '1.0.0';

  // ============================================================================
  // API TIMEOUT CONFIGURATION
  // ============================================================================

  /// Connection timeout duration
  static const Duration connectTimeout = Duration(seconds: 30);

  /// Receive timeout duration
  static const Duration receiveTimeout = Duration(seconds: 30);

  /// Send timeout duration
  static const Duration sendTimeout = Duration(seconds: 30);

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Convert internal server URLs to CDN URLs for images
  /// This improves performance by serving images from CDN instead of backend
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
  /// Used for external URLs that might be missing the protocol
  static String ensureHttps(String url) {
    if (url.isEmpty) return url;

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    return 'https://$url';
  }

  /// Get full API URL by appending path to base URL
  static String getApiUrl(String path) {
    if (path.startsWith('/')) {
      return '$apiBaseUrl$path';
    }
    return '$apiBaseUrl/$path';
  }
}
