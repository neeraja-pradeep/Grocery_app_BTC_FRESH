import 'dart:developer' as developer;
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

  /// Fetches product variant detail with If-Modified-Since optimization.
  ///
  /// DESIGN: Metadata-only Hive caching (following category feature pattern)
  ///
  /// Returns:
  /// - ProductVariant: Server returned 200 OK (new data, UI will refresh)
  /// - null: Server returned 304 Not Modified (no change, UI stays same)
  ///
  /// FLOW:
  /// -----
  /// 1. Get cached metadata (lastModified, eTag) from Hive
  /// 2. Always fetch from API with If-Modified-Since header
  /// 3. Server response:
  ///    - 304: No change on server, return null (UI doesn't refresh)
  ///    - 200: New data from server, save metadata, return data (UI refreshes)
  ///
  /// WHY METADATA-ONLY CACHING:
  /// --------------------------
  /// - Product data is in-memory in Riverpod state (not persistent)
  /// - On navigate away/back: forceRefresh=true fetches fresh data
  /// - Only metadata (lastModified, eTag) cached for conditional requests
  /// - Saves bandwidth: 304 responses are ~1KB vs full product data (50-100KB)
  @override
  Future<ProductVariant?> getProductDetail(
    String variantId, {
    bool forceRefresh = false,
  }) async {
    try {
      // Get cached metadata (NOT product data)
      final cachedMetadata = await _localDataSource.getCachedProductDetail(
        variantId,
      );

      // Log cache state
      if (cachedMetadata != null && !forceRefresh) {
        final now = DateTime.now();
        final cacheAge = now.difference(cachedMetadata.lastSyncedAt);
        developer.log(
          'Variant $variantId: Metadata age ${cacheAge.inSeconds}s (TTL ${cacheTTL.inSeconds}s)',
          name: 'ProductRepo',
        );
      }

      // Always fetch from API (only metadata prevents re-download on 304)
      final remoteResponse = await _remoteDataSource.fetchProductDetail(
        productId: variantId,
        ifNoneMatch: forceRefresh ? null : cachedMetadata?.eTag,
        ifModifiedSince: forceRefresh ? null : cachedMetadata?.lastModified,
      );

      final now = DateTime.now();

      // 304 Not Modified - data unchanged on server
      if (remoteResponse == null) {
        developer.log(
          'Variant $variantId: 304 Not Modified (no UI refresh)',
          name: 'ProductRepo',
        );

        // Update lastSyncedAt to refresh TTL
        if (cachedMetadata != null) {
          await _localDataSource.cacheProductDetailWithMetadata(
            variantId,
            cachedMetadata.copyWith(lastSyncedAt: now),
          );
        }

        // Return null - controller won't update state/UI
        return null;
      }

      // 200 OK - new data from server
      developer.log(
        'Variant $variantId: 200 OK (UI will refresh)',
        name: 'ProductRepo',
      );

      // Save ONLY metadata (lastModified, eTag) to Hive
      // Product data is in Riverpod state (in-memory), not persistent
      final newCacheDto = cache_dto.ProductDetailCacheDto(
        lastSyncedAt: now,
        eTag: remoteResponse.eTag,
        lastModified: remoteResponse.lastModified,
      );

      await _localDataSource.cacheProductDetailWithMetadata(
        variantId,
        newCacheDto,
      );

      return remoteResponse.productDetail.toDomain();
    } catch (e) {
      developer.log('Variant $variantId: Error - $e', name: 'ProductRepo');

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
