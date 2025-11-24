/// Global configuration for product details feature
///
/// Centralized place for all timing and behavioral constants
/// used across the product details feature
class ProductDetailConfig {
  /// HTTP conditional request polling interval
  ///
  /// How often to send If-Modified-Since requests to check for updates:
  /// - Variant API: GET /api/products/variants/{variantId}/
  /// - Product API: GET /api/products/{productId}/
  ///
  /// Server responses:
  /// - 304 Not Modified: No change, metadata cached in Hive, UI not updated
  /// - 200 OK: New data, metadata updated, UI refreshes
  ///
  /// Why 30 seconds?
  /// - Balances responsiveness (real-time updates) with bandwidth efficiency
  /// - 304 responses are ~1KB vs full product data (50-100KB)
  /// - Prevents excessive API calls while keeping UI fresh
  static const Duration pollingInterval = Duration(seconds: 30);

  /// Cache TTL (time-to-live) for HTTP metadata
  ///
  /// How long to keep cached If-Modified-Since / ETag headers:
  /// - Used to determine when to send conditional request headers
  /// - Prevents using stale metadata older than this duration
  static const Duration cacheMetadataTTL = Duration(hours: 1);

  /// Refresh indicator display duration
  ///
  /// How long to show the refresh indicator (loading spinner) after:
  /// - Polling refresh starts
  /// - API request completes (200 or 304)
  static const Duration refreshIndicatorDuration = Duration(milliseconds: 1500);

  /// Product detail cache key namespace
  ///
  /// Single Hive box 'cache' with namespaced keys to avoid collisions:
  /// - variant_metadata:{variantId} → Variant API If-Modified-Since metadata
  /// - product_metadata:{productId} → Product API If-Modified-Since metadata
  /// - reviews:{productId} → Product reviews cache
  /// - wishlist → User's wishlist items
  ///
  /// This ensures all conditional request metadata is stored efficiently
  /// without creating multiple Hive boxes
  static const String hiveBoxName = 'cache';
  static const String variantMetadataPrefix = 'variant_metadata:';
  static const String productMetadataPrefix = 'product_metadata:';
  static const String reviewsPrefix = 'reviews:';
  static const String wishlistKey = 'wishlist';
}
