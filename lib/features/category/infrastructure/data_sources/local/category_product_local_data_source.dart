import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../../core/storage/hive/boxes.dart';
import '../../../../../core/storage/cache_config.dart';
import '../../../../../core/utils/logger.dart';
import 'category_product_cache_dto.dart';

/// Manages local caching of category products using Hive.
///
/// L1: in-memory Map — sub-millisecond reads on cache hits.
/// L2: Hive disk store — persists across app restarts.
class CategoryProductLocalDataSource {
  CategoryProductLocalDataSource();

  static String get _cacheKeyPrefix =>
      CacheConfig.categoryProductMetadataPrefix;

  Box<dynamic> get _box => Hive.box<dynamic>(Boxes.cache);

  // L1 in-memory cache keyed by categoryId
  final Map<String, CategoryProductCacheDto> _memCache = {};

  /// Reads the cached products for a category.
  /// Checks L1 memory first, falls back to Hive (L2) on miss.
  CategoryProductCacheDto? read(String categoryId) {
    // L1 hit
    final memHit = _memCache[categoryId];
    if (memHit != null) return memHit;

    // L2 (Hive)
    try {
      final key = '$_cacheKeyPrefix$categoryId';
      final cached = _box.get(key);
      if (cached == null) return null;

      if (cached is Map) {
        final jsonMap = Map<String, dynamic>.from(cached);
        final dto = CategoryProductCacheDto.fromJson(jsonMap);
        _memCache[categoryId] = dto; // Populate L1
        return dto;
      }
      return null;
    } on HiveError catch (e) {
      Logger.error('Hive error reading product cache for $categoryId', error: e);
      _evict(categoryId);
      return null;
    } catch (e) {
      Logger.warning(
        'Failed to parse product cache for $categoryId — entry deleted',
        error: e,
      );
      _evict(categoryId);
      return null;
    }
  }

  /// Saves the category products and Last-Modified header to Hive and L1.
  Future<void> save(CategoryProductCacheDto dto) async {
    _memCache[dto.categoryId] = dto; // Update L1 immediately
    try {
      final key = '$_cacheKeyPrefix${dto.categoryId}';
      await _box.put(key, dto.toJson());
    } on HiveError catch (e) {
      Logger.error('Failed to save product cache for ${dto.categoryId}', error: e);
    } catch (e) {
      Logger.warning(
        'Unexpected error saving product cache for ${dto.categoryId}',
        error: e,
      );
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
        await save(updated);
      }
    } on HiveError catch (e) {
      Logger.error('Failed to update product cache timestamp for $categoryId', error: e);
    } catch (e) {
      Logger.warning(
        'Unexpected error updating product cache timestamp for $categoryId',
        error: e,
      );
    }
  }

  /// Clears cached products for a specific category from memory and Hive.
  Future<void> clear(String categoryId) async {
    _memCache.remove(categoryId);
    try {
      final key = '$_cacheKeyPrefix$categoryId';
      await _box.delete(key);
    } on HiveError catch (e) {
      Logger.error('Failed to clear product cache for $categoryId', error: e);
    } catch (e) {
      Logger.warning(
        'Unexpected error clearing product cache for $categoryId',
        error: e,
      );
    }
  }

  void _evict(String categoryId) {
    _memCache.remove(categoryId);
    try {
      _box.delete('$_cacheKeyPrefix$categoryId');
    } catch (_) {}
  }
}
