// lib/features/wishlist/infrastructure/repositories/wishlist_repository_impl.dart

import 'package:new_app/features/home/domain/repositories/wishlist_repository.dart';
import 'package:new_app/features/wishlist/domain/entities/wishlist_item.dart';

import 'package:new_app/features/wishlist/infrastructure/data_sources/wishlist_api.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistDataSource _dataSource;

  WishlistRepositoryImpl(this._dataSource);

  @override
  Future<List<WishlistItem>> getWishlist() {
    return _dataSource.getWishlist();
  }

  @override
  Future<WishlistItem> addToWishlist(String productId) {
    return _dataSource.addToWishlist(productId);
  }

  @override
  Future<WishlistItem> getWishlistItem(String id) {
    return _dataSource.getWishlistItem(id);
  }

  @override
  Future<WishlistItem> updateWishlistItem(
    String id,
    Map<String, dynamic> data,
  ) {
    return _dataSource.updateWishlistItem(id, data);
  }

  @override
  Future<void> removeFromWishlist(String id) {
    return _dataSource.removeFromWishlist(id);
  }
}
