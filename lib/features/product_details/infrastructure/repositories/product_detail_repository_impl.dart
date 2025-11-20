import '../../domain/entities/product_variant.dart';
import '../../domain/repositories/product_detail_repository.dart';
import '../data_sources/local/product_detail_local_data_source.dart';
import '../data_sources/local/product_detail_cache_dto.dart' as cache_dto;
import '../data_sources/remote/product_detail_remote_data_source.dart';

/// Implementation of ProductDetailRepository
/// Combines local cache and remote API with HTTP conditional headers support
class ProductDetailRepositoryImpl implements ProductDetailRepository {
  ProductDetailRepositoryImpl({
    required ProductDetailLocalDataSource localDataSource,
    required ProductDetailRemoteDataSource remoteDataSource,
    this.cacheTTL = const Duration(hours: 1),
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final ProductDetailLocalDataSource _localDataSource;
  final ProductDetailRemoteDataSource _remoteDataSource;
  final Duration cacheTTL;

  /// Fetches product detail with smart caching using HTTP conditional requests.
  ///
  /// ALGORITHM:
  /// ----------
  /// 1. Check local Hive cache:
  ///    - If cache is fresh (age < 1 hour): Return cached data (no network)
  ///    - If cache is stale/missing: Proceed to conditional request
  ///
  /// 2. Send conditional GET request with headers:
  ///    - If-Modified-Since: lastModified from Hive
  ///    - If-None-Match: eTag from Hive
  ///
  /// 3. Handle server response:
  ///    - 304 Not Modified (null response):
  ///      * Data hasn't changed on server
  ///      * Update lastSyncedAt in Hive (refresh TTL)
  ///      * Return cached data (BANDWIDTH SAVED!)
  ///    - 200 OK (response with data):
  ///      * New data available from server
  ///      * Save new data + NEW lastModified to Hive
  ///      * Return fresh data
  ///
  /// 4. Error handling:
  ///    - Network error: Fallback to cached data if available
  ///
  /// BANDWIDTH OPTIMIZATION:
  /// ---------------------
  /// When data is unchanged:
  /// - 304 response: ~1KB (just headers)
  /// - Without caching: Full product data (10-50KB)
  /// - Saving per check: 99% bandwidth saved
  @override
  Future<ProductVariant> getProductDetail(String productId) async {
    try {
      // Step 1: Check if we have cached data with metadata
      final cachedData = await _localDataSource.getCachedProductDetail(
        productId,
      );
      final now = DateTime.now();

      // If cache exists and is still fresh (< TTL), return immediately (no network!)
      if (cachedData != null) {
        final cacheAge = now.difference(cachedData.lastSyncedAt);
        if (cacheAge < cacheTTL) {
          return cachedData.productDetail.toDomain();
        }
      }

      // Step 2: Cache is stale or doesn't exist - fetch with conditional headers
      // The remote data source will send If-Modified-Since with lastModified value
      final remoteResponse = await _remoteDataSource.fetchProductDetail(
        productId: productId,
        ifNoneMatch: cachedData?.eTag,
        ifModifiedSince: cachedData?.lastModified,
      );

      // Step 3: Handle 304 Not Modified response
      // remoteResponse is null when server returns 304 (data unchanged)
      if (remoteResponse == null) {
        // Update lastSyncedAt to refresh the TTL timer
        if (cachedData != null) {
          await _localDataSource.cacheProductDetailWithMetadata(
            productId,
            cachedData.copyWith(lastSyncedAt: now),
          );
        }
        return cachedData!.productDetail.toDomain();
      }

      // Step 4: Got 200 OK - new data is available, cache it with headers
      final newCacheDto = cache_dto.ProductDetailCacheDto(
        productDetail: remoteResponse.productDetail,
        lastSyncedAt: now,
        eTag: remoteResponse.eTag,
        lastModified: remoteResponse
            .lastModified, // ← Use NEW lastModified for next request
      );
      await _localDataSource.cacheProductDetailWithMetadata(
        productId,
        newCacheDto,
      );

      return remoteResponse.productDetail.toDomain();
    } catch (e) {
      // Step 5: Network error? Fallback to local cache if available
      final cachedData = await _localDataSource.getCachedProductDetail(
        productId,
      );
      if (cachedData != null) {
        return cachedData.productDetail.toDomain();
      }
      rethrow;
    }
  }

  @override
  Future<List<ProductVariantReview>> getProductReviews(String productId) async {
    try {
      // Try to fetch from remote first
      final remoteReviews = await _remoteDataSource.getProductReviews(
        productId,
      );

      // Cache the result
      await _localDataSource.cacheProductReviews(productId, remoteReviews);

      return remoteReviews.map((e) => e.toDomain()).toList();
    } catch (e) {
      // Fallback to local cache on error
      final cachedReviews = await _localDataSource.getProductReviews(productId);
      if (cachedReviews != null) {
        return cachedReviews.map((e) => e.toDomain()).toList();
      }
      rethrow;
    }
  }

  @override
  Future<ProductVariant> getProductVariant(String variantId) async {
    try {
      // Fetch from remote API
      final remoteVariant = await _remoteDataSource.getProductVariant(
        variantId,
      );
      return remoteVariant.toDomain();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> isInWishlist(String productId) async {
    try {
      // Check remote first
      return await _remoteDataSource.isInWishlist(productId);
    } catch (e) {
      // Fallback to local cache
      return await _localDataSource.isInWishlist(productId);
    }
  }

  @override
  Future<void> addToWishlist(String productId) async {
    try {
      // Add to remote
      await _remoteDataSource.addToWishlist(productId);

      // Also add to local cache
      await _localDataSource.addToWishlist(productId);
    } catch (e) {
      // If remote fails, still add to local
      await _localDataSource.addToWishlist(productId);
      rethrow;
    }
  }

  @override
  Future<void> removeFromWishlist(String productId) async {
    try {
      // Remove from remote
      await _remoteDataSource.removeFromWishlist(productId);

      // Also remove from local cache
      await _localDataSource.removeFromWishlist(productId);
    } catch (e) {
      // If remote fails, still remove from local
      await _localDataSource.removeFromWishlist(productId);
      rethrow;
    }
  }
}
