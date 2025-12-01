// lib/features/wishlist/infrastructure/data_sources/wishlist_local_ds.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/features/wishlist/domain/entities/wishlist_item.dart';

// Cached data container with timestamp
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

class WishlistLocalDataSourceImpl implements WishlistLocalDataSource {
  // In-memory cache for now - in a real app, you'd use Hive/SharedPreferences
  CachedWishlistData? _cachedWishlist;

  @override
  Future<CachedWishlistData?> getWishlist() async {
    return _cachedWishlist;
  }

  @override
  Future<void> saveWishlist(List<WishlistItem> items) async {
    _cachedWishlist = CachedWishlistData(data: items, cachedAt: DateTime.now());
  }

  @override
  Future<void> clearWishlistCache() async {
    _cachedWishlist = null;
  }
}

final wishlistLocalDataSourceProvider = Provider<WishlistLocalDataSource>((
  ref,
) {
  return WishlistLocalDataSourceImpl();
});
