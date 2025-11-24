/// Global cache configuration used across the entire app
///
/// This centralizes all caching settings for:
/// - HTTP conditional request polling intervals
/// - Cache TTL (Time To Live)
/// - Hive key prefixes for different features
/// - Refresh indicator timing
///
/// All features use a single Hive box (AppHiveBoxes.cache = 'app_cache_box')
/// with proper namespacing to organize different data types.
///
/// USAGE:
/// ------
/// Instead of each feature having its own config, use CacheConfig across:
/// - Product Details feature
/// - Category feature
/// - Any other feature with If-Modified-Since caching
///
/// MEMORY EFFICIENCY:
/// ------------------
/// Single Hive box prevents creating multiple boxes (which consume memory).
/// Namespaced keys keep different features' data organized and separated.
class CacheConfig {
  const CacheConfig._();

  // ============================================================================
  // GLOBAL TIMING CONFIGURATION (used by all features)
  // ============================================================================

  /// Polling interval for ALL API requests with conditional caching
  ///
  /// How often to send If-Modified-Since requests to check for updates.
  ///
  /// Applies to:
  /// - Product details (variant API + product API)
  /// - Category list
  /// - Category products
  /// - Any other API endpoint with conditional request support
  ///
  /// Why 30 seconds?
  /// - Balances responsiveness (real-time updates) with bandwidth efficiency
  /// - 304 Not Modified responses are ~1KB vs full response body (50-100KB)
  /// - Prevents excessive API calls while keeping UI fresh
  static const Duration pollingInterval = Duration(seconds: 30);

  /// Cache TTL (Time To Live) for HTTP conditional request metadata
  ///
  /// How long to keep cached If-Modified-Since / ETag headers before
  /// considering them stale and requiring a fresh API request.
  ///
  /// Used to determine:
  /// - Whether to send conditional headers (if metadata is fresh)
  /// - When cached metadata expires and needs refresh
  static const Duration cacheTTL = Duration(hours: 1);

  /// Duration for showing refresh indicator during polling
  ///
  /// How long to display the loading/refresh indicator after:
  /// - Polling refresh starts
  /// - API request completes (200 OK or 304 Not Modified)
  ///
  /// Creates a visible feedback for user that data is being checked
  static const Duration refreshIndicatorDuration = Duration(milliseconds: 1500);

  // ============================================================================
  // HIVE BOX CONFIGURATION (all stored in single 'app_cache_box')
  // ============================================================================

  /// Hive box name for all caching
  ///
  /// All features store their If-Modified-Since metadata in this single box
  /// using namespaced keys to avoid collisions
  static const String hiveBoxName = 'app_cache_box';

  // ============================================================================
  // PRODUCT DETAIL FEATURE - Key Prefixes (pd: = product detail)
  // ============================================================================

  /// Product Details - Variant API metadata cache
  /// Format: 'pd:variant_meta:{variantId}'
  /// Stores: lastSyncedAt, lastModified, eTag
  static const String productDetailVariantMetadataPrefix = 'pd:variant_meta:';

  /// Product Details - Product API metadata cache
  /// Format: 'pd:product_meta:{productId}'
  /// Stores: lastSyncedAt, lastModified, eTag
  static const String productDetailProductMetadataPrefix = 'pd:product_meta:';

  // ============================================================================
  // CATEGORY FEATURE - Key Prefixes (cat: = category)
  // ============================================================================

  /// Category List - Metadata cache
  /// Format: 'cat:list_meta'
  /// Stores: lastSyncedAt, lastModified, eTag, category list
  static const String categoryMetadataKey = 'cat:list_meta';

  /// Category Products - Metadata cache
  /// Format: 'cat:products_meta:{categoryId}'
  /// Stores: lastSyncedAt, lastModified, eTag, product list
  static const String categoryProductMetadataPrefix = 'cat:products_meta:';

  // ============================================================================
  // ADD NEW FEATURES HERE
  // ============================================================================
  // When adding new features with If-Modified-Since caching:
  // 1. Define key prefix with descriptive namespace (e.g., 'feature_abbreviation:')
  // 2. Use consistent naming: 'feature_name:data_type:'
  // 3. Reference in CacheConfig for global access
  // 4. Document what data is stored and format of keys
}
