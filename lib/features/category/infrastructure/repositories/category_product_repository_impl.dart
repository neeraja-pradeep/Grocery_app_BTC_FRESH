import '../../../../core/storage/cache_config.dart';
import '../../../../core/storage/cache_schema.dart';
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
    Duration cacheTtl = CacheConfig.cacheTTL,
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
    // A truncated cache counts as stale regardless of age, so the section
    // refreshes it immediately instead of showing a short list for up to a TTL.
    final isStale = _isStale(cache.lastSyncedAt) || _isIncomplete(cache);

    return CategoryProductRepositoryResult(
      products: products,
      isFromCache: true,
      lastSyncedAt: cache.lastSyncedAt,
      isStale: isStale,
      totalCount: cache.count,
      next: cache.next,
      previous: cache.previous,
      eTag: cache.eTag,
      lastModified: cache.lastModified,
    );
  }

  /// Syncs products for a category with conditional request headers for efficiency.
  ///
  /// LOGIC:
  /// ------
  /// 1. Reads lastModified from Hive cache for this category
  /// 2. Sends GET request with If-Modified-Since header (if cache exists)
  /// 3. Handles responses:
  ///    - Server returns 200 (OK): Data changed, save new products + lastModified to Hive
  ///    - Server returns 304 (Not Modified): Data unchanged, just update lastSyncedAt
  /// 4. [forceRemote] = true: Bypasses conditional headers for force refresh
  ///
  /// WHY THIS WORKS:
  /// ---------------
  /// The server compares the If-Modified-Since timestamp with when the
  /// resource was last modified. If the timestamp matches or is newer,
  /// the server returns 304 instead of resending the products.
  ///
  /// PER-CATEGORY:
  /// Each category's products are cached independently, so changes to one
  /// category don't affect cached data for other categories.
  @override
  Future<CategoryProductRepositoryResult> syncProducts(
    String categoryId, {
    bool forceRemote = false,
  }) async {
    final existingCache = _localDataSource.read(categoryId);

    // A cache written before pagination was followed holds only the first page
    // but carries perfectly valid validators. Replaying them would get a 304
    // and pin the truncated list in place forever, so drop the validators and
    // refetch in full until the entry has been rewritten by this build.
    final skipValidators =
        forceRemote || (existingCache != null && _isIncomplete(existingCache));

    final response = await _remoteDataSource.fetchProducts(
      categoryId,
      // If forceRemote, send no headers (get full response)
      // Otherwise, use lastModified from Hive for If-Modified-Since
      ifNoneMatch: skipValidators ? null : existingCache?.eTag,
      ifModifiedSince: skipValidators ? null : existingCache?.lastModified,
    );

    // Server returned 304 (Not Modified) - products haven't changed
    if (response == null) {
      if (existingCache == null) {
        return const CategoryProductRepositoryResult(
          products: <CategoryProduct>[],
          isFromCache: true,
          lastSyncedAt: null,
          isStale: false,
        );
      }

      final now = DateTime.now();
      // Only update the lastSyncedAt timestamp, keep the cached products
      await _localDataSource.updateLastSyncedAt(categoryId, now);

      return CategoryProductRepositoryResult(
        products: _mapDtosToDomain(existingCache.products),
        isFromCache: true,
        lastSyncedAt: now,
        isStale: false,
        totalCount: existingCache.count,
        next: existingCache.next,
        previous: existingCache.previous,
        eTag: existingCache.eTag,
        lastModified: existingCache.lastModified,
      );
    }

    // Server returned 200 (OK) - new products available
    final cacheDto = CategoryProductCacheDto(
      categoryId: categoryId,
      products: response.products,
      lastSyncedAt: response.fetchedAt,
      eTag: response.eTag ?? existingCache?.eTag,
      // Save the NEW lastModified from response for next If-Modified-Since
      lastModified: response.lastModified ?? existingCache?.lastModified,
      count: response.count ?? existingCache?.count,
      // The data source drains every page before returning, so there is no
      // further page. Not `?? existingCache?.next` — that would resurrect a
      // stale page-2 link written before pagination was followed, leaving the
      // cache claiming more data exists when it has all of it.
      next: response.next,
      previous: response.previous,
    );

    await _localDataSource.save(cacheDto);

    return CategoryProductRepositoryResult(
      products: _mapDtosToDomain(response.products),
      isFromCache: false,
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

  /// True when the entry was written by a build that did not follow
  /// pagination, so it holds only the first 25 products.
  ///
  /// Deliberately a schema-version check rather than `products.length < count`:
  /// `count` counts *products* while the cache stores one entry per *variant*,
  /// and products with no variants are dropped entirely — so the two numbers
  /// legitimately disagree and a length comparison would force a full refetch
  /// on every sync.
  bool _isIncomplete(CategoryProductCacheDto cache) =>
      cache.schemaVersion < CacheSchema.categoryProducts;

  List<CategoryProduct> _mapDtosToDomain(List<CategoryProductDto> dtos) =>
      dtos.map((dto) => dto.toDomain()).toList(growable: false);
}
