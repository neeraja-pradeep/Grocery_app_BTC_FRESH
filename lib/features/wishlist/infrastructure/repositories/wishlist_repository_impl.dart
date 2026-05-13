// lib/features/wishlist/infrastructure/repositories/wishlist_repository_impl.dart

import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/storage/cache_config.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/wishlist_item.dart';
import '../../domain/repositories/wishlist_repository.dart';
import '../data_sources/wishlist_api.dart';
import '../data_sources/wishlist_local_ds.dart';

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
    // 1. Try fresh cache first
    try {
      final cachedContainer = await _localDataSource.getWishlist();
      if (cachedContainer != null &&
          cachedContainer.isFresh(CacheConfig.wishlistCacheTtl)) {
        return Right(cachedContainer.data);
      }
    } catch (_) {
      // Cache read failure — proceed to API
    }

    // 2. Fetch from API
    try {
      final items = await _remoteDataSource.getWishlist();
      await _localDataSource.saveWishlist(items);
      return Right(items);
    } on DioException catch (e) {
      // 3. On network error, return stale cache if available
      final stale = await _getStaleCacheOrNull();
      if (stale != null) return Right(stale);

      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.unknown) {
        return const Left(NetworkFailure());
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return const Left(TimeoutFailure());
      }
      return Left(
        ServerFailure(
          e.message ?? 'Server error',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      final stale = await _getStaleCacheOrNull();
      if (stale != null) return Right(stale);
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, WishlistItem>> addToWishlist(String productId) async {
    try {
      final item = await _remoteDataSource.addToWishlist(productId);
      await _refreshCache();
      return Right(item);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Failed to add to wishlist',
          statusCode: e.response?.statusCode,
        ),
      );
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
      await _refreshCache();
      return const Right(null);
    } on DioException catch (e) {
      return Left(
        ServerFailure(
          e.message ?? 'Failed to remove from wishlist',
          statusCode: e.response?.statusCode,
        ),
      );
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFromWishlistByProductId(
    String productId,
  ) async {
    final wishlistResult = await getWishlist();

    return wishlistResult.fold((failure) => Left(failure), (items) async {
      WishlistItem? item;
      try {
        item = items.firstWhere((item) => item.productId == productId);
      } catch (_) {
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
      Logger.error('Failed to clear wishlist cache', error: e);
    }
  }

  Future<List<WishlistItem>?> _getStaleCacheOrNull() async {
    try {
      final cached = await _localDataSource.getWishlist();
      return cached?.data;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshCache() async {
    try {
      final items = await _remoteDataSource.getWishlist();
      await _localDataSource.saveWishlist(items);
    } catch (_) {
      // Ignore cache refresh errors
    }
  }
}
