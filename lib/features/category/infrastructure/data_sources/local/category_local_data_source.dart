import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../../core/storage/hive/boxes.dart';
import '../../../../../core/storage/cache_config.dart';
import 'category_cache_dto.dart';

/// Manages local caching of category data using Hive.
class CategoryLocalDataSource {
  CategoryLocalDataSource();

  // Use global cache key prefix for consistency with all features
  static String get _cacheKey => CacheConfig.categoryMetadataKey;

  Box<dynamic> get _box => Hive.box<dynamic>(Boxes.cache);

  /// Reads the cached category data from Hive.
  CategoryCacheDto? read() {
    try {
      final cached = _box.get(_cacheKey);
      if (cached == null) return null;

      // Hive stores Maps as Map<dynamic, dynamic>, not Map<String, dynamic>
      if (cached is Map) {
        final jsonMap = Map<String, dynamic>.from(cached);
        return CategoryCacheDto.fromJson(jsonMap);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Saves the category data and Last-Modified header to Hive.
  Future<void> save(CategoryCacheDto dto) async {
    try {
      await _box.put(_cacheKey, dto.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Updates the last synced timestamp without changing category data.
  Future<void> updateLastSyncedAt(DateTime timestamp) async {
    try {
      final cached = read();
      if (cached != null) {
        final updated = CategoryCacheDto(
          categories: cached.categories,
          lastSyncedAt: timestamp,
          eTag: cached.eTag,
          lastModified: cached.lastModified,
          count: cached.count,
          next: cached.next,
          previous: cached.previous,
        );
        await _box.put(_cacheKey, updated.toJson());
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Clears all cached category data from Hive.
  Future<void> clear() async {
    try {
      await _box.delete(_cacheKey);
    } catch (e) {
      rethrow;
    }
  }
}
