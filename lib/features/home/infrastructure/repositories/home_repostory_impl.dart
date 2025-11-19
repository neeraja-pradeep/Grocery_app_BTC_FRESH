// lib/features/home/infrastructure/repositories/home_repository_impl.dart

import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:new_app/core/error/failure.dart'; // Corrected import name (plural)
import 'package:new_app/features/home/domain/entities/banner.dart';
import 'package:new_app/features/home/domain/entities/category.dart';
import 'package:new_app/features/home/domain/entities/category_discount_group.dart';
import 'package:new_app/features/home/domain/entities/product_variant.dart';
import 'package:new_app/features/home/domain/entities/user_address.dart';
import 'package:new_app/features/home/domain/repositories/home_repository.dart';
import 'package:new_app/features/home/infrastructure/data_sources/remote/home_api.dart';
import 'package:new_app/features/home/infrastructure/data_sources/local/home_local_ds.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource _remoteDataSource;
  final HomeLocalDataSource _localDataSource;

  HomeRepositoryImpl({
    required HomeRemoteDataSource remoteDataSource,
    required HomeLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  // --- Helper: Group Variants into Categories ---
  List<CategoryDiscountGroup> _groupVariants(List<ProductVariant> variants) {
    final Map<int, List<ProductVariant>> groupedMap = {};

    for (var variant in variants) {
      // Logic: Group by productId (or categoryId if you add it to the variant entity later)
      final catId = variant.productId;
      if (!groupedMap.containsKey(catId)) {
        groupedMap[catId] = [];
      }
      groupedMap[catId]!.add(variant);
    }

    final List<CategoryDiscountGroup> groups = [];
    groupedMap.forEach((key, value) {
      // Create a placeholder category since the API variant endpoint doesn't return full category info
      final dummyCategory = Category(
        id: key,
        name:
            "Deal Category $key", // You might map this ID to a known category name if available
        slug: "deal-$key",
        description: "",
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      groups.add(
        CategoryDiscountGroup(
          category: dummyCategory,
          discountedProducts: value,
        ),
      );
    });
    return groups;
  }

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
          return Right(
            PaginatedResult(
              count: cachedContainer.data.length,
              results: cachedContainer.data,
            ),
          );
        }
      } catch (e) {
        // Ignore cache read errors, proceed to API
      }
    }

    // 2. Fetch from API
    try {
      // Updated method name: getCategories
      final result = await _remoteDataSource.getCategories(page: page);

      // 3. Save to Cache (only page 1)
      if (page == 1) {
        await _localDataSource.saveCategories(result.results);
      }

      return Right(result);
    } catch (e) {
      // 4. On Network Error: Try to return stale cache if available
      if (page == 1) {
        try {
          final cachedContainer = await _localDataSource.getCategories();
          if (cachedContainer != null) {
            return Right(
              PaginatedResult(
                count: cachedContainer.data.length,
                results: cachedContainer.data,
              ),
            );
          }
        } catch (_) {}
      }
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CategoryDiscountGroup>>>
  getDiscountedProductsByCategory({
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
        // Convert flat list to groups
        return Right(_groupVariants(cachedContainer.data));
      }
    } catch (_) {}

    // 2. Fetch from API
    try {
      // Updated method name: getDiscountedProducts
      final variants = await _remoteDataSource.getDiscountedProducts(
        parentCategoryName: parentCategoryName,
        minPrice: minPrice,
        maxPrice: maxPrice,
        ordering: ordering,
      );

      // 3. Save to Cache (Store the flat list)
      await _localDataSource.saveDiscountedProducts(
        cacheKey: cacheKey,
        products: variants,
      );

      // 4. Convert and Return
      return Right(_groupVariants(variants));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
          return Right(cachedContainer.data);
        }
      } catch (_) {}
    }

    // 2. Fetch
    try {
      // Updated method name: getBanners
      final result = await _remoteDataSource.getBanners(page: page);

      // 3. Save
      if (page == 1) {
        await _localDataSource.saveBanners(result.results);
      }
      return Right(result.results);
    } catch (e) {
      // 4. Fallback
      if (page == 1) {
        try {
          final cachedContainer = await _localDataSource.getBanners();
          if (cachedContainer != null) return Right(cachedContainer.data);
        } catch (_) {}
      }
      return Left(ServerFailure(e.toString()));
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
        return Right(cachedContainer.data);
      }
    } catch (_) {}

    // 2. Fetch
    try {
      // Updated method name: getBestDeals
      final result = await _remoteDataSource.getBestDeals(limit: limit);

      await _localDataSource.saveBestDeals(result);

      return Right(result);
    } catch (e) {
      // 3. Fallback
      try {
        final cachedContainer = await _localDataSource.getBestDeals();
        if (cachedContainer != null) return Right(cachedContainer.data);
      } catch (_) {}

      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ProductVariant>>> searchProducts({
    required String query,
    int page = 1,
  }) async {
    try {
      // Updated method name: searchProducts
      final result = await _remoteDataSource.searchProducts(
        query: query,
        page: page,
      );

      // Not saving search results to cache (strategy decision),
      // but we do not have access to "saveSearchHistory" in Local DS in this file scope?
      // If you need to save the query string to history, you need to expose that method in Local DS.
      // Assuming clean architecture, we just return data here.

      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserAddress?>> getSelectedAddress() async {
    // 1. Check Cache
    try {
      final cached = await _localDataSource.getSelectedAddress();
      if (cached != null) return Right(cached);
    } catch (_) {}

    // 2. Fetch
    try {
      final address = await _remoteDataSource.getSelectedAddress();
      if (address != null) {
        await _localDataSource.saveSelectedAddress(address);
      }
      return Right(address);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
