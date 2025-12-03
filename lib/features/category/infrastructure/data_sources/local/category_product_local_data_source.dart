import 'package:hive_flutter/hive_flutter.dart';

import '../../../../../core/storage/hive/boxes.dart';
import '../../../../../core/storage/cache_config.dart';
import 'category_product_cache_dto.dart';

/// Manages local caching of category products using Hive.
///
/// This data source is responsible for persisting per-category:
/// - Product list data
/// - Last sync timestamp
/// - Last-Modified header (for If-Modified-Since checks)
/// - ETag and pagination info
///
/// Storage key format: 'cat:products_meta:{categoryId}'
/// Uses the global cache key prefix from CacheConfig for consistency.
/// This allows caching multiple category products independently.
class CategoryProductLocalDataSource {
  CategoryProductLocalDataSource();

  // Use global cache key prefix for consistency with all features
  static String get _cacheKeyPrefix =>
      CacheConfig.categoryProductMetadataPrefix;

  Box<dynamic> get _box => Hive.box<dynamic>(AppHiveBoxes.cache);

  /// Reads the cached products for a category from Hive.
  ///
  /// Returns null if no cache exists for this category.
  CategoryProductCacheDto? read(String categoryId) {
    try {
      final key = '$_cacheKeyPrefix$categoryId';
      final cached = _box.get(key);
      if (cached == null) return null;

      // Hive stores Maps as Map<dynamic, dynamic>, not Map<String, dynamic>
      // We need to convert it properly before deserializing
      if (cached is Map) {
        final jsonMap = Map<String, dynamic>.from(cached);
        return CategoryProductCacheDto.fromJson(jsonMap);
      }
      return null;
    } catch (e) {
      // If deserialization fails, return null and allow fresh fetch
      return null;
    }
  }

  /// Saves the category products and Last-Modified header to Hive.
  ///
  /// This persists:
  /// - Product list for this category
  /// - Last sync timestamp
  /// - Last-Modified header (used for next If-Modified-Since request)
  /// - ETag and pagination info
  ///
  /// Each category's products are stored separately using categoryId,
  /// so caching multiple categories doesn't affect each other.
  Future<void> save(CategoryProductCacheDto dto) async {
    try {
      final key = '$_cacheKeyPrefix${dto.categoryId}';
      await _box.put(key, dto.toJson());
    } catch (e) {
      // Silently fail if caching fails - data will be fetched next time
      rethrow;
    }
  }

  /// Updates the last synced timestamp without changing product data.
  ///
  /// This is called when the server returns 304 Not Modified,
  /// indicating products haven't changed but we've checked recently.
  /// Updates only the lastSyncedAt timestamp to reset the TTL.
  Future<void> updateLastSyncedAt(String categoryId, DateTime timestamp) async {
    try {
      final cached = read(categoryId);
      if (cached != null) {
        final updated = CategoryProductCacheDto(
          categoryId: cached.categoryId,
          products: cached.products,
          lastSyncedAt: timestamp,
          eTag: cached.eTag,
          lastModified: cached.lastModified,
          count: cached.count,
          next: cached.next,
          previous: cached.previous,
        );
        final key = '$_cacheKeyPrefix$categoryId';
        await _box.put(key, updated.toJson());
      }
    } catch (e) {
      // Silently fail if update fails
      rethrow;
    }
  }

  /// Clears all cached products for a specific category from Hive.
  Future<void> clear(String categoryId) async {
    try {
      final key = '$_cacheKeyPrefix$categoryId';
      await _box.delete(key);
    } catch (e) {
      // Silently fail if clearing fails
      rethrow;
    }
  }
}
