// lib/features/home/infrastructure/repositories/home_repository_impl.dart

import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/banner.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_variant.dart';
import '../../domain/entities/user_address.dart';
import '../../domain/repositories/home_repository.dart';
import '../data_sources/remote/home_api.dart';
import '../data_sources/local/home_local_ds.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;
  final HomeLocalDataSource _localDataSource;

  HomeRepositoryImpl({
    required HomeRemoteDataSource remoteDataSource,
    required HomeLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  /// Converts exceptions to appropriate failures
  // Failure _handleException(Object exception) {
  //   if (exception is NetworkException || exception is TimeoutException) {
  //     return NetworkFailure(exception.toString());
  //   } else if (exception is ServerException) {
  //     return ServerFailure(
  //       exception.toString(),
  //       statusCode: exception.statusCode,
  //     );
  //   } else if (exception is DataParsingException) {
  //     return DataParsingFailure(exception.toString());
  //   } else if (exception is CacheException) {
  //     return CacheFailure(exception.toString());
  //   } else if (exception is NotFoundException) {
  //     return ServerFailure(exception.toString(), statusCode: 404);
  //   } else if (exception is UnauthorizedException) {
  //     return ServerFailure(exception.toString(), statusCode: 401);
  //   } else {
  //     return UnknownFailure('Unexpected error: ${exception.toString()}');
  //   }
  // }

  @override
  Future<Either<Failure, PaginatedResult<Category>>> getCategories({
    int page = 1,
  }) async {
    // 1. Try Local Cache first (only for first page)
    if (page == 1) {
      try {
        final cachedContainer = await _localDataSource.getCategories();
        if (cachedContainer != null &&
            cachedContainer.isFresh(const Duration(hours: 1))) {
          Logger.debug('Categories loaded from cache');
          return Right(
            PaginatedResult(
              count: cachedContainer.data.length,
              results: cachedContainer.data,
            ),
          );
        }
      } on HiveError catch (e) {
        Logger.error('Hive cache read error for categories', error: e);
        // Continue to API fetch
      } catch (e) {
        Logger.error('Unexpected cache error for categories', error: e);
        // Continue to API fetch
      }
    }

    // 2. Fetch from API
    try {
      final result = await _remoteDataSource.getCategories(page: page);
      Logger.debug(
        'Categories loaded from API: ${result.results.length} items',
      );

      // 3. Save to Cache (only page 1)
      if (page == 1) {
        try {
          await _localDataSource.saveCategories(result.results);
          Logger.debug('Categories saved to cache');
        } on HiveError catch (e) {
          Logger.error('Failed to save categories to cache', error: e);
          // Don't fail the request if cache save fails
        } catch (e) {
          Logger.error('Unexpected error saving categories to cache', error: e);
        }
      }

      return Right(result);
    } on NetworkException catch (e) {
      Logger.warning('Network error fetching categories', error: e);
      // 4. On Network Error: Try to return stale cache if available
      if (page == 1) {
        try {
          final cachedContainer = await _localDataSource.getCategories();
          if (cachedContainer != null) {
            Logger.info('Returning stale cache due to network error');
            return Right(
              PaginatedResult(
                count: cachedContainer.data.length,
                results: cachedContainer.data,
              ),
            );
          }
        } catch (cacheError) {
          Logger.error('Failed to retrieve stale cache', error: cacheError);
        }
      }
      return Left(NetworkFailure(e.toString()));
    } on ServerException catch (e) {
      Logger.error('Server error fetching categories', error: e);
      return Left(ServerFailure(e.toString(), statusCode: e.statusCode));
    } catch (e) {
      Logger.error('Unexpected error fetching categories', error: e);
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ProductVariant>>> getDiscountedProducts({
    String? parentCategoryName,
    double? minPrice,
    double? maxPrice,
    String ordering = '-discounted_price',
  }) async {
    // Generate a unique cache key
    final cacheKey = '${parentCategoryName ?? "all"}_$ordering';

    // 1. Check Cache
    try {
      final cachedContainer = await _localDataSource.getDiscountedProducts(
        cacheKey: cacheKey,
      );
      if (cachedContainer != null &&
          cachedContainer.isFresh(const Duration(minutes: 10))) {
        Logger.debug('Discounted products loaded from cache: $cacheKey');
        return Right(cachedContainer.data);
      }
    } on HiveError catch (e) {
      Logger.error('Hive cache read error for discounted products', error: e);
    } catch (e) {
      Logger.error('Unexpected cache error for discounted products', error: e);
    }

    // 2. Fetch from API
    try {
      final variants = await _remoteDataSource.getDiscountedProducts(
        parentCategoryName: parentCategoryName,
        minPrice: minPrice,
        maxPrice: maxPrice,
        ordering: ordering,
      );
      Logger.debug(
        'Discounted products loaded from API: ${variants.length} items',
      );

      // 3. Save to Cache (Store the flat list)
      try {
        await _localDataSource.saveDiscountedProducts(
          cacheKey: cacheKey,
          products: variants,
        );
        Logger.debug('Discounted products saved to cache: $cacheKey');
      } on HiveError catch (e) {
        Logger.error('Failed to save discounted products to cache', error: e);
      } catch (e) {
        Logger.error(
          'Unexpected error saving discounted products to cache',
          error: e,
        );
      }

      // 4. Return raw product variants (no business logic grouping)
      return Right(variants);
    } on NetworkException catch (e) {
      Logger.warning('Network error fetching discounted products', error: e);
      return Left(NetworkFailure(e.toString()));
    } on ServerException catch (e) {
      Logger.error('Server error fetching discounted products', error: e);
      return Left(ServerFailure(e.toString(), statusCode: e.statusCode));
    } catch (e) {
      Logger.error('Unexpected error fetching discounted products', error: e);
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Banner>>> getBanners({int page = 1}) async {
    // 1. Check Cache
    if (page == 1) {
      try {
        final cachedContainer = await _localDataSource.getBanners();
        if (cachedContainer != null &&
            cachedContainer.isFresh(const Duration(minutes: 30))) {
          Logger.debug('Banners loaded from cache');
          return Right(cachedContainer.data);
        }
      } on HiveError catch (e) {
        Logger.error('Hive cache read error for banners', error: e);
      } catch (e) {
        Logger.error('Unexpected cache error for banners', error: e);
      }
    }

    // 2. Fetch
    try {
      final result = await _remoteDataSource.getBanners(page: page);
      Logger.debug('Banners loaded from API: ${result.results.length} items');

      // 3. Save
      if (page == 1) {
        try {
          await _localDataSource.saveBanners(result.results);
          Logger.debug('Banners saved to cache');
        } on HiveError catch (e) {
          Logger.error('Failed to save banners to cache', error: e);
        } catch (e) {
          Logger.error('Unexpected error saving banners to cache', error: e);
        }
      }
      return Right(result.results);
    } on NetworkException catch (e) {
      Logger.warning('Network error fetching banners', error: e);
      // 4. Fallback to stale cache
      if (page == 1) {
        try {
          final cachedContainer = await _localDataSource.getBanners();
          if (cachedContainer != null) {
            Logger.info('Returning stale banners cache due to network error');
            return Right(cachedContainer.data);
          }
        } catch (cacheError) {
          Logger.error(
            'Failed to retrieve stale banners cache',
            error: cacheError,
          );
        }
      }
      return Left(NetworkFailure(e.toString()));
    } on ServerException catch (e) {
      Logger.error('Server error fetching banners', error: e);
      return Left(ServerFailure(e.toString(), statusCode: e.statusCode));
    } catch (e) {
      Logger.error('Unexpected error fetching banners', error: e);
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ProductVariant>>> getBestDeals({
    int limit = 10,
  }) async {
    // 1. Check Cache
    try {
      final cachedContainer = await _localDataSource.getBestDeals();
      if (cachedContainer != null &&
          cachedContainer.isFresh(const Duration(minutes: 10))) {
        Logger.debug('Best deals loaded from cache');
        return Right(cachedContainer.data);
      }
    } on HiveError catch (e) {
      Logger.error('Hive cache read error for best deals', error: e);
    } catch (e) {
      Logger.error('Unexpected cache error for best deals', error: e);
    }

    // 2. Fetch
    try {
      final result = await _remoteDataSource.getBestDeals(limit: limit);
      Logger.debug('Best deals loaded from API: ${result.length} items');

      try {
        await _localDataSource.saveBestDeals(result);
        Logger.debug('Best deals saved to cache');
      } on HiveError catch (e) {
        Logger.error('Failed to save best deals to cache', error: e);
      } catch (e) {
        Logger.error('Unexpected error saving best deals to cache', error: e);
      }

      return Right(result);
    } on NetworkException catch (e) {
      Logger.warning('Network error fetching best deals', error: e);
      // 3. Fallback to stale cache
      try {
        final cachedContainer = await _localDataSource.getBestDeals();
        if (cachedContainer != null) {
          Logger.info('Returning stale best deals cache due to network error');
          return Right(cachedContainer.data);
        }
      } catch (cacheError) {
        Logger.error(
          'Failed to retrieve stale best deals cache',
          error: cacheError,
        );
      }
      return Left(NetworkFailure(e.toString()));
    } on ServerException catch (e) {
      Logger.error('Server error fetching best deals', error: e);
      return Left(ServerFailure(e.toString(), statusCode: e.statusCode));
    } catch (e) {
      Logger.error('Unexpected error fetching best deals', error: e);
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ProductVariant>>> searchProducts({
    required String query,
    int page = 1,
  }) async {
    try {
      final result = await _remoteDataSource.searchProducts(
        query: query,
        page: page,
      );
      Logger.debug('Search results for "$query": ${result.length} items');

      return Right(result);
    } on NetworkException catch (e) {
      Logger.warning('Network error searching products for "$query"', error: e);
      return Left(NetworkFailure(e.toString()));
    } on ServerException catch (e) {
      Logger.error('Server error searching products for "$query"', error: e);
      return Left(ServerFailure(e.toString(), statusCode: e.statusCode));
    } catch (e) {
      Logger.error(
        'Unexpected error searching products for "$query"',
        error: e,
      );
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, UserAddress?>> getSelectedAddress() async {
    // 1. Check Cache
    try {
      final cached = await _localDataSource.getSelectedAddress();
      if (cached != null) {
        Logger.debug('Selected address loaded from cache');
        return Right(cached);
      }
    } on HiveError catch (e) {
      Logger.error('Hive cache read error for selected address', error: e);
    } catch (e) {
      Logger.error('Unexpected cache error for selected address', error: e);
    }

    // 2. Fetch
    try {
      final address = await _remoteDataSource.getSelectedAddress();
      Logger.debug(
        'Selected address loaded from API: ${address != null ? 'found' : 'not found'}',
      );

      if (address != null) {
        try {
          await _localDataSource.saveSelectedAddress(address);
          Logger.debug('Selected address saved to cache');
        } on HiveError catch (e) {
          Logger.error('Failed to save selected address to cache', error: e);
        } catch (e) {
          Logger.error(
            'Unexpected error saving selected address to cache',
            error: e,
          );
        }
      }
      return Right(address);
    } on NetworkException catch (e) {
      Logger.warning('Network error fetching selected address', error: e);
      return Left(NetworkFailure(e.toString()));
    } on ServerException catch (e) {
      Logger.error('Server error fetching selected address', error: e);
      return Left(ServerFailure(e.toString(), statusCode: e.statusCode));
    } catch (e) {
      Logger.error('Unexpected error fetching selected address', error: e);
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Either<Failure, PaginatedResult<Product>>> searchProductsWithVariants({
    required String query,
    int page = 1,
  }) async {
    try {
      final result = await _remoteDataSource.searchProductsWithVariants(
        query: query,
        page: page,
      );
      Logger.debug(
        'Product search results for "$query": ${result.results.length} items',
      );

      return Right(result);
    } on NetworkException catch (e) {
      Logger.warning('Network error searching products for "$query"', error: e);
      return Left(NetworkFailure(e.toString()));
    } on ServerException catch (e) {
      Logger.error('Server error searching products for "$query"', error: e);
      return Left(ServerFailure(e.toString(), statusCode: e.statusCode));
    } catch (e) {
      Logger.error(
        'Unexpected error searching products for "$query"',
        error: e,
      );
      return Left(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      await _localDataSource.clearAllHomeCache();
      Logger.info('Home cache cleared successfully');
    } on HiveError catch (e) {
      Logger.error('Hive error clearing cache', error: e);
      // Don't throw - cache clearing should be non-blocking
    } catch (e) {
      Logger.error('Unexpected error clearing cache', error: e);
      // Don't throw - cache clearing should be non-blocking
    }
  }
}

final homeRepositoryProvider = riverpod.Provider<HomeRepository>((ref) {
  final remoteDs = ref.watch(homeRemoteDataSourceProvider);
  final localDs = ref.watch(homeLocalDataSourceProvider);
  return HomeRepositoryImpl(
    remoteDataSource: remoteDs,
    localDataSource: localDs,
  );
});
