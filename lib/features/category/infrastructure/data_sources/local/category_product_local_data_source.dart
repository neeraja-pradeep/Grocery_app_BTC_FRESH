import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../../core/storage/hive/boxes.dart';
import '../../../../../core/storage/cache_config.dart';
import 'category_product_cache_dto.dart';

/// Manages local caching of category products using Hive.
class CategoryProductLocalDataSource {
  CategoryProductLocalDataSource();

  // Use global cache key prefix for consistency with all features
  static String get _cacheKeyPrefix =>
      CacheConfig.categoryProductMetadataPrefix;

  Box<dynamic> get _box => Hive.box<dynamic>(Boxes.cache);

  /// Reads the cached products for a category from Hive.
  CategoryProductCacheDto? read(String categoryId) {
    try {
      final key = '$_cacheKeyPrefix$categoryId';
      final cached = _box.get(key);
      if (cached == null) return null;

      // Hive stores Maps as Map<dynamic, dynamic>, not Map<String, dynamic>
      if (cached is Map) {
        final jsonMap = Map<String, dynamic>.from(cached);
        return CategoryProductCacheDto.fromJson(jsonMap);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Saves the category products and Last-Modified header to Hive.
  Future<void> save(CategoryProductCacheDto dto) async {
    try {
      final key = '$_cacheKeyPrefix${dto.categoryId}';
      await _box.put(key, dto.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Updates the last synced timestamp without changing product data.
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
      rethrow;
    }
  }

  /// Clears all cached products for a specific category from Hive.
  Future<void> clear(String categoryId) async {
    try {
      final key = '$_cacheKeyPrefix$categoryId';
      await _box.delete(key);
    } catch (e) {
      rethrow;
    }
  }
}
