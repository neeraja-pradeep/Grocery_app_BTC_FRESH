import 'package:hive_flutter/hive_flutter.dart';

import '../../../../../core/storage/hive/boxes.dart';
import '../../../../../core/storage/cache_config.dart';
import 'category_cache_dto.dart';

/// Manages local caching of category data using Hive.
///
/// This data source is responsible for persisting:
/// - Category list data
/// - Last sync timestamp
/// - Last-Modified header (for If-Modified-Since checks)
/// - ETag and pagination info
///
/// Uses centralized Hive box (AppHiveBoxes.cache) with global key prefix
/// from CacheConfig to maintain consistency across all features.
class CategoryLocalDataSource {
  CategoryLocalDataSource();

  // Use global cache key prefix for consistency with all features
  static String get _cacheKey => CacheConfig.categoryMetadataKey;

  Box<dynamic> get _box => Hive.box<dynamic>(AppHiveBoxes.cache);

  /// Reads the cached category data from Hive.
  ///
  /// Returns null if no cache exists.
  CategoryCacheDto? read() {
    try {
      final cached = _box.get(_cacheKey);
      if (cached == null) return null;

      // Hive stores Maps as Map<dynamic, dynamic>, not Map<String, dynamic>
      // We need to convert it properly before deserializing
      if (cached is Map) {
        final jsonMap = Map<String, dynamic>.from(cached);
        return CategoryCacheDto.fromJson(jsonMap);
      }
      return null;
    } catch (e) {
      // If deserialization fails, return null and allow fresh fetch
      return null;
    }
  }

  /// Saves the category data and Last-Modified header to Hive.
  ///
  /// This persists:
  /// - Category list
  /// - Last sync timestamp
  /// - Last-Modified header (used for next If-Modified-Since request)
  /// - ETag and pagination info
  Future<void> save(CategoryCacheDto dto) async {
    try {
      await _box.put(_cacheKey, dto.toJson());
    } catch (e) {
      // Silently fail if caching fails - data will be fetched next time
      rethrow;
    }
  }

  /// Updates the last synced timestamp without changing category data.
  ///
  /// This is called when the server returns 304 Not Modified,
  /// indicating data hasn't changed but we've checked recently.
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
      // Silently fail if update fails
      rethrow;
    }
  }

  /// Clears all cached category data from Hive.
  Future<void> clear() async {
    try {
      await _box.delete(_cacheKey);
    } catch (e) {
      // Silently fail if clearing fails
      rethrow;
    }
  }
}
