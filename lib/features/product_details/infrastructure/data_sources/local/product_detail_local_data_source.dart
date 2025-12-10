import 'package:hive_ce_flutter/hive_flutter.dart';

import './product_detail_cache_dto.dart';
import '../../../../../core/storage/hive/boxes.dart';
import '../../../../../core/storage/cache_config.dart';

/// Local data source for caching ONLY HTTP conditional request metadata.
///
/// This uses the centralized Hive box (AppHiveBoxes.cache) with namespaced keys
/// to store ONLY metadata (NOT product data).
///
/// Data stored:
/// - lastSyncedAt: When we last synced with server (used for cache TTL)
/// - lastModified: HTTP Last-Modified header (for If-Modified-Since requests)
/// - eTag: HTTP ETag header (for If-None-Match requests)
///
/// Product data is NOT stored here - it's in-memory in Riverpod state.
/// When user navigates away/back, forceRefresh=true fetches fresh data.
///
/// Conditional Request Flow (following category feature pattern):
/// 1. Send If-Modified-Since header with cached lastModified
/// 2. Server returns 304 → No change, return null (no UI refresh)
/// 3. Server returns 200 → Cache metadata and return fresh product data (UI refreshes)
///
/// Key Prefixes (using CacheConfig):
/// - Variant API: CacheConfig.productDetailVariantMetadataPrefix (pd:variant_meta:)
/// - Product API: CacheConfig.productDetailProductMetadataPrefix (pd:product_meta:)
abstract class ProductDetailLocalDataSource {
  /// Get cached metadata headers.
  ///
  /// Returns:
  /// - ProductDetailCacheDto containing ONLY metadata (lastModified, eTag, lastSyncedAt)
  /// - null if no cache exists
  ///
  /// The repository uses this metadata to construct If-Modified-Since headers
  /// for conditional requests to optimize bandwidth.
  Future<ProductDetailCacheDto?> getCachedProductDetail(String productId);

  /// Cache metadata headers only.
  ///
  /// Stores:
  /// - lastSyncedAt: Timestamp for cache TTL tracking
  /// - lastModified: HTTP Last-Modified header (for next If-Modified-Since)
  /// - eTag: HTTP ETag header (for next If-None-Match)
  ///
  /// NOTE: Product data is NOT stored here.
  /// Product data is in Riverpod state (in-memory), not persistent in Hive.
  Future<void> cacheProductDetailWithMetadata(
    String productId,
    ProductDetailCacheDto cacheDto,
  );

  /// Clear cached product detail.
  ///
  /// Removes both the product data and its metadata from Hive.
  Future<void> clearProductDetail(String productId);

  /// Get cached metadata headers for product base API.
  ///
  /// Returns:
  /// - ProductDetailCacheDto containing ONLY metadata (lastModified, eTag, lastSyncedAt)
  /// - null if no cache exists
  ///
  /// Separate from getCachedProductDetail() to keep variant and product API caches distinct.
  Future<ProductDetailCacheDto?> getCachedProductBase(String productId);

  /// Cache metadata headers only for product base API.
  ///
  /// Stores:
  /// - lastSyncedAt: Timestamp for cache TTL tracking
  /// - lastModified: HTTP Last-Modified header (for next If-Modified-Since)
  /// - eTag: HTTP ETag header (for next If-None-Match)
  ///
  /// Uses separate cache key prefix to distinguish from variant API cache.
  Future<void> cacheProductBaseWithMetadata(
    String productId,
    ProductDetailCacheDto cacheDto,
  );
}

/// Implementation using centralized Hive box
class ProductDetailLocalDataSourceImpl implements ProductDetailLocalDataSource {
  ProductDetailLocalDataSourceImpl();

  // Use centralized Hive box shared across all features
  Box<dynamic> get _box => Hive.box<dynamic>(AppHiveBoxes.cache);

  // Use centralized cache configuration for key prefixes
  static String get _variantMetadataPrefix =>
      CacheConfig.productDetailVariantMetadataPrefix;

  static String get _productMetadataPrefix =>
      CacheConfig.productDetailProductMetadataPrefix;

  @override
  Future<ProductDetailCacheDto?> getCachedProductDetail(
    String productId,
  ) async {
    try {
      final key = '$_variantMetadataPrefix$productId';
      final json = _box.get(key) as Map<String, dynamic>?;
      return json != null ? ProductDetailCacheDto.fromJson(json) : null;
    } catch (e) {
      return null;
    }
  }

  /// Update last synced timestamp without changing metadata.
  ///
  /// Called when server returns 304 Not Modified to reset cache TTL.
  Future<void> updateProductDetailSyncTime(
    String productId,
    DateTime timestamp,
  ) async {
    try {
      final cached = await getCachedProductDetail(productId);
      if (cached != null) {
        await cacheProductDetailWithMetadata(
          productId,
          cached.copyWith(lastSyncedAt: timestamp),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> cacheProductDetailWithMetadata(
    String productId,
    ProductDetailCacheDto cacheDto,
  ) async {
    try {
      final key = '$_variantMetadataPrefix$productId';
      await _box.put(key, cacheDto.toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> clearProductDetail(String productId) async {
    try {
      final key = '$_variantMetadataPrefix$productId';
      await _box.delete(key);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ProductDetailCacheDto?> getCachedProductBase(String productId) async {
    try {
      final key = '$_productMetadataPrefix$productId';
      final json = _box.get(key) as Map<String, dynamic>?;
      return json != null ? ProductDetailCacheDto.fromJson(json) : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheProductBaseWithMetadata(
    String productId,
    ProductDetailCacheDto cacheDto,
  ) async {
    try {
      final key = '$_productMetadataPrefix$productId';
      await _box.put(key, cacheDto.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Clear all cached product details
  Future<void> clearAllCache() async {
    try {
      final keys = _box.keys.toList();
      for (final key in keys) {
        if (key.toString().startsWith(_variantMetadataPrefix)) {
          await _box.delete(key);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
