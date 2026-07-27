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

  static String get _syncedAtKeyPrefix =>
      CacheConfig.categoryProductSyncedAtPrefix;

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
        var dto = CategoryProductCacheDto.fromJson(jsonMap);

        // The "last checked" time is stored under its own key (see
        // [updateLastSyncedAt]), so overlay it when it is newer than the
        // timestamp embedded in the product blob.
        final syncedAt = _readSyncedAt(categoryId);
        if (syncedAt != null && syncedAt.isAfter(dto.lastSyncedAt)) {
          dto = dto.withLastSyncedAt(syncedAt);
        }

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

  /// Reads the separately-stored "last checked" timestamp, if any.
  DateTime? _readSyncedAt(String categoryId) {
    try {
      final raw = _box.get('$_syncedAtKeyPrefix$categoryId');
      if (raw is String) return DateTime.tryParse(raw)?.toLocal();
    } catch (_) {
      // A malformed timestamp is not worth failing the cache read over — the
      // blob's own lastSyncedAt is a safe fallback.
    }
    return null;
  }

  /// Saves the category products and Last-Modified header to Hive and L1.
  Future<void> save(CategoryProductCacheDto dto) async {
    _memCache[dto.categoryId] = dto; // Update L1 immediately
    try {
      final key = '$_cacheKeyPrefix${dto.categoryId}';
      await _box.put(key, dto.toJson());
      // The blob now carries an up-to-date lastSyncedAt, so any overlay
      // timestamp is stale and would only confuse a later read.
      await _box.delete('$_syncedAtKeyPrefix${dto.categoryId}');
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
  ///
  /// Called on every 304 Not Modified, i.e. once per category per poll tick.
  /// It writes a single ISO string to its own key rather than re-serialising
  /// the whole product list through [save] — that previously turned the
  /// *cheap* branch of the polling loop into the expensive one, JSON-encoding
  /// every cached product and rewriting it to disk every 30s per category.
  Future<void> updateLastSyncedAt(String categoryId, DateTime timestamp) async {
    // L1 is authoritative while the app is running, so keep it exact.
    final cached = _memCache[categoryId] ?? read(categoryId);
    if (cached == null) return;
    _memCache[categoryId] = cached.withLastSyncedAt(timestamp);

    try {
      await _box.put(
        '$_syncedAtKeyPrefix$categoryId',
        timestamp.toIso8601String(),
      );
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
      await _box.delete('$_syncedAtKeyPrefix$categoryId');
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
      _box.delete('$_syncedAtKeyPrefix$categoryId');
    } catch (_) {}
  }
}
