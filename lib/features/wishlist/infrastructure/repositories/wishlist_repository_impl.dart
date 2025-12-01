// lib/features/wishlist/infrastructure/repositories/wishlist_repository_impl.dart

import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:grocery_app/core/error/failure.dart';
import 'package:grocery_app/features/wishlist/domain/entities/wishlist_item.dart';
import 'package:grocery_app/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:grocery_app/features/wishlist/infrastructure/data_sources/wishlist_api.dart';
import 'package:grocery_app/features/wishlist/infrastructure/data_sources/wishlist_local_ds.dart';

class WishlistRepositoryImpl implements WishlistRepository {
  final WishlistRemoteDataSource _remoteDataSource;
  final WishlistLocalDataSource _localDataSource;

  WishlistRepositoryImpl({
    required WishlistRemoteDataSource remoteDataSource,
    required WishlistLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  @override
  Future<Either<Failure, List<WishlistItem>>> getWishlist() async {
    // 1. Try Local Cache first
    try {
      final cachedContainer = await _localDataSource.getWishlist();
      if (cachedContainer != null &&
          cachedContainer.isFresh(const Duration(minutes: 5))) {
        return Right(cachedContainer.data);
      }
    } catch (e) {
      // Ignore cache read errors, proceed to API
    }

    // 2. Fetch from API
    try {
      final items = await _remoteDataSource.getWishlist();

      // 3. Save to Cache
      await _localDataSource.saveWishlist(items);

      return Right(items);
    } catch (e) {
      // 4. On Network Error: Try to return stale cache if available
      try {
        final cachedContainer = await _localDataSource.getWishlist();
        if (cachedContainer != null) {
          return Right(cachedContainer.data);
        }
      } catch (_) {}

      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WishlistItem>> addToWishlist(String productId) async {
    try {
      final item = await _remoteDataSource.addToWishlist(productId);

      // Update cache by refetching the entire wishlist
      // This ensures consistency but could be optimized
      await _refreshCache();

      return Right(item);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFromWishlist(
    String wishlistItemId,
  ) async {
    try {
      await _remoteDataSource.removeFromWishlist(wishlistItemId);

      // Update cache by refetching the entire wishlist
      await _refreshCache();

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFromWishlistByProductId(
    String productId,
  ) async {
    // First get the current wishlist to find the item
    final wishlistResult = await getWishlist();

    return wishlistResult.fold((failure) => Left(failure), (items) async {
      WishlistItem? item;
      try {
        item = items.firstWhere((item) => item.productId == productId);
      } catch (e) {
        item = null;
      }

      if (item == null) {
        return const Left(ServerFailure('Item not found in wishlist'));
      }

      return removeFromWishlist(item.id.toString());
    });
  }

  @override
  Future<Either<Failure, bool>> isInWishlist(String productId) async {
    final wishlistResult = await getWishlist();

    return wishlistResult.fold(
      (failure) => Left(failure),
      (items) => Right(items.any((item) => item.productId == productId)),
    );
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localDataSource.clearWishlistCache();
    } catch (e) {
      // Log error but don't throw - cache clearing should be non-blocking
      // Log error but don't throw - cache clearing should be non-blocking
    }
  }

  // Helper method to refresh cache
  Future<void> _refreshCache() async {
    try {
      final items = await _remoteDataSource.getWishlist();
      await _localDataSource.saveWishlist(items);
    } catch (e) {
      // Ignore cache refresh errors
    }
  }
}

final wishlistRepositoryProvider = riverpod.Provider<WishlistRepository>((ref) {
  final remoteDs = ref.watch(wishlistRemoteDataSourceProvider);
  final localDs = ref.watch(wishlistLocalDataSourceProvider);
  return WishlistRepositoryImpl(
    remoteDataSource: remoteDs,
    localDataSource: localDs,
  );
});
