// lib/features/wishlist/domain/repositories/wishlist_repository.dart

import 'package:fpdart/fpdart.dart';
import 'package:new_app/core/error/failure.dart';
import 'package:new_app/features/wishlist/domain/entities/wishlist_item.dart';

abstract class WishlistRepository {
  /// Gets all wishlist items for the current user
  Future<Either<Failure, List<WishlistItem>>> getWishlist();

  /// Adds a product to the wishlist
  Future<Either<Failure, WishlistItem>> addToWishlist(String productId);

  /// Removes an item from the wishlist by wishlist item ID
  Future<Either<Failure, void>> removeFromWishlist(String wishlistItemId);

  /// Removes an item from the wishlist by product ID
  Future<Either<Failure, void>> removeFromWishlistByProductId(String productId);

  /// Checks if a product is in the wishlist
  Future<Either<Failure, bool>> isInWishlist(String productId);

  /// Clears all cached wishlist data
  Future<void> clearCache();
}
