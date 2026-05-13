// lib/features/wishlist/infrastructure/data_sources/wishlist_local_ds.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/storage/cache_config.dart';
import '../../../../core/storage/hive/boxes.dart';
import '../../domain/entities/wishlist_item.dart';

/// Container wrapping a cached wishlist with its timestamp for TTL checks.
class CachedWishlistData {
  final List<WishlistItem> data;
  final DateTime cachedAt;

  CachedWishlistData({required this.data, required this.cachedAt});

  bool isFresh(Duration maxAge) {
    return DateTime.now().difference(cachedAt) < maxAge;
  }
}

abstract class WishlistLocalDataSource {
  Future<CachedWishlistData?> getWishlist();
  Future<void> saveWishlist(List<WishlistItem> items);
  Future<void> clearWishlistCache();
}

/// Hive-backed wishlist cache — survives app restarts.
class WishlistLocalDataSourceImpl implements WishlistLocalDataSource {
  @override
  Future<CachedWishlistData?> getWishlist() async {
    try {
      final raw = Boxes.cacheBox.get(CacheConfig.wishlistCacheKey);
      if (raw == null) return null;

      final map = raw as Map;
      final cachedAt = DateTime.parse(map['cachedAt'] as String);
      final itemsList = (map['items'] as List)
          .map((e) => WishlistItemX.fromCacheJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList();

      return CachedWishlistData(data: itemsList, cachedAt: cachedAt);
    } catch (e, st) {
      debugPrint('[WishlistLocalDs] cache read failed: $e\n$st');
      await clearWishlistCache();
      return null;
    }
  }

  @override
  Future<void> saveWishlist(List<WishlistItem> items) async {
    try {
      final payload = {
        'cachedAt': DateTime.now().toIso8601String(),
        'items': items.map((item) => item.toCacheJson()).toList(),
      };
      await Boxes.cacheBox.put(CacheConfig.wishlistCacheKey, payload);
    } catch (e, st) {
      debugPrint('[WishlistLocalDs] cache write failed: $e\n$st');
    }
  }

  @override
  Future<void> clearWishlistCache() async {
    try {
      await Boxes.cacheBox.delete(CacheConfig.wishlistCacheKey);
    } catch (e, st) {
      debugPrint('[WishlistLocalDs] cache clear failed: $e\n$st');
    }
  }
}

final wishlistLocalDataSourceProvider = Provider<WishlistLocalDataSource>((
  ref,
) {
  return WishlistLocalDataSourceImpl();
});
