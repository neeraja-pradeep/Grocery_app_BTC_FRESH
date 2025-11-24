import '../../../../core/storage/cache_config.dart';

/// Feature-level configuration for product details
///
/// DEPRECATED: Use CacheConfig instead for global consistency
///
/// This class is maintained for backward compatibility but now delegates
/// to CacheConfig to ensure all features use the same timing and naming.
///
/// The global CacheConfig provides:
/// - Consistent polling intervals across all features
/// - Single Hive box to reduce memory usage
/// - Centralized key prefixes to prevent collisions
class ProductDetailConfig {
  /// HTTP conditional request polling interval
  ///
  /// Delegates to global CacheConfig.pollingInterval for consistency
  /// across all features (product details, category, etc)
  static Duration get pollingInterval => CacheConfig.pollingInterval;

  /// Cache TTL (time-to-live) for HTTP conditional request metadata
  ///
  /// Delegates to global CacheConfig.cacheTTL
  static Duration get cacheMetadataTTL => CacheConfig.cacheTTL;

  /// Refresh indicator display duration
  ///
  /// Delegates to global CacheConfig.refreshIndicatorDuration
  static Duration get refreshIndicatorDuration =>
      CacheConfig.refreshIndicatorDuration;

  /// Product detail cache key namespace
  ///
  /// DEPRECATED: Use CacheConfig constants directly
  /// All data stored in single Hive box with namespaced keys
  ///
  /// Variant API metadata: pd:variant_meta:{variantId}
  /// Product API metadata: pd:product_meta:{productId}
  static String get hiveBoxName => CacheConfig.hiveBoxName;
  static String get variantMetadataPrefix =>
      CacheConfig.productDetailVariantMetadataPrefix;
  static String get productMetadataPrefix =>
      CacheConfig.productDetailProductMetadataPrefix;
}
