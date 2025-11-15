import '../../domain/entities/category_product.dart';
import '../../domain/repositories/category_product_repository.dart';
import '../data_sources/local/category_product_cache_dto.dart';
import '../data_sources/local/category_product_local_data_source.dart';
import '../data_sources/remote/category_product_remote_data_source.dart';
import '../models/category_product_dto.dart';

class CategoryProductRepositoryImpl implements CategoryProductRepository {
  CategoryProductRepositoryImpl({
    required CategoryProductLocalDataSource localDataSource,
    required CategoryProductRemoteDataSource remoteDataSource,
    Duration cacheTtl = const Duration(minutes: 10),
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _cacheTtl = cacheTtl;

  final CategoryProductLocalDataSource _localDataSource;
  final CategoryProductRemoteDataSource _remoteDataSource;
  final Duration _cacheTtl;

  @override
  Duration get cacheTtl => _cacheTtl;

  @override
  Future<CategoryProductRepositoryResult?> getCachedProducts(
    String categoryId,
  ) async {
    final cache = _localDataSource.read(categoryId);
    if (cache == null) return null;

    final products = _mapDtosToDomain(cache.products);
    final isStale = _isStale(cache.lastSyncedAt);

    return CategoryProductRepositoryResult(
      products: products,
      source: CategoryProductDataSource.cache,
      lastSyncedAt: cache.lastSyncedAt,
      isStale: isStale,
      totalCount: cache.count,
      next: cache.next,
      previous: cache.previous,
      eTag: cache.eTag,
      lastModified: cache.lastModified,
    );
  }

  @override
  Future<CategoryProductRepositoryResult> syncProducts(
    String categoryId, {
    bool forceRemote = false,
  }) async {
    final existingCache = _localDataSource.read(categoryId);

    final response = await _remoteDataSource.fetchProducts(
      categoryId,
      ifNoneMatch: forceRemote ? null : existingCache?.eTag,
      ifModifiedSince: forceRemote ? null : existingCache?.lastModified,
    );

    if (response == null) {
      if (existingCache == null) {
        return const CategoryProductRepositoryResult(
          products: <CategoryProduct>[],
          source: CategoryProductDataSource.cache,
          lastSyncedAt: null,
          isStale: false,
        );
      }

      final now = DateTime.now();
      await _localDataSource.updateLastSyncedAt(categoryId, now);

      return CategoryProductRepositoryResult(
        products: _mapDtosToDomain(existingCache.products),
        source: CategoryProductDataSource.cache,
        lastSyncedAt: now,
        isStale: false,
        totalCount: existingCache.count,
        next: existingCache.next,
        previous: existingCache.previous,
        eTag: existingCache.eTag,
        lastModified: existingCache.lastModified,
      );
    }

    final cacheDto = CategoryProductCacheDto(
      categoryId: categoryId,
      products: response.products,
      lastSyncedAt: response.fetchedAt,
      eTag: response.eTag ?? existingCache?.eTag,
      lastModified: response.lastModified ?? existingCache?.lastModified,
      count: response.count ?? existingCache?.count,
      next: response.next ?? existingCache?.next,
      previous: response.previous ?? existingCache?.previous,
    );

    await _localDataSource.save(cacheDto);

    return CategoryProductRepositoryResult(
      products: _mapDtosToDomain(response.products),
      source: CategoryProductDataSource.remote,
      lastSyncedAt: response.fetchedAt,
      isStale: false,
      totalCount: response.count,
      next: response.next,
      previous: response.previous,
      eTag: response.eTag ?? existingCache?.eTag,
      lastModified: response.lastModified ?? existingCache?.lastModified,
    );
  }

  bool _isStale(DateTime lastSyncedAt) {
    final now = DateTime.now();
    return now.difference(lastSyncedAt) >= _cacheTtl;
  }

  List<CategoryProduct> _mapDtosToDomain(List<CategoryProductDto> dtos) =>
      dtos.map((dto) => dto.toDomain()).toList(growable: false);
}
