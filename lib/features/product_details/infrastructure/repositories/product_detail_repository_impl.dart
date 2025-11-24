import 'dart:developer' as developer;
import '../../domain/entities/product_variant.dart';
import '../../domain/entities/product_base.dart';
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
  Future<ProductBase?> getProductBase(
    String productId, {
    bool forceRefresh = false,
  }) async {
    try {
      // Product API: Always fetch FRESH data (NO If-Modified-Since logic)
      //
      // IMPORTANT: The product API endpoint does NOT properly support
      // If-Modified-Since headers. Therefore, we ALWAYS fetch fresh data
      // without conditional request headers.
      //
      // This is different from the variant API which has proper Last-Modified support.
      //
      // Strategy:
      // - Variant API: Uses If-Modified-Since (bandwidth optimized, gets 304)
      // - Product API: Always fetches fresh (ensures latest description/rating/media)
      // - Polling: Still happens only every 30 seconds (not wasteful)

      developer.log(
        'ProductBase $productId: Fetching fresh (no If-Modified-Since support)',
        name: 'ProductRepo',
      );

      // Always fetch fresh without conditional headers
      final remoteResponse = await _remoteDataSource.fetchProductBase(
        productId: productId,
        ifNoneMatch: null, // ← SKIP conditional requests
        ifModifiedSince: null, // ← SKIP conditional requests
      );

      // Product API should always return fresh data (200 OK)
      if (remoteResponse == null) {
        developer.log(
          'ProductBase $productId: Got null response (unexpected)',
          name: 'ProductRepo',
        );
        // Return null to keep existing cached data in state
        return null;
      }

      developer.log(
        'ProductBase $productId: 200 OK (fresh data fetched)',
        name: 'ProductRepo',
      );

      return remoteResponse.productBase.toDomain();
    } catch (e) {
      developer.log('ProductBase $productId: Error - $e', name: 'ProductRepo');

      rethrow;
    }
  }

  @override
  Future<List<ProductVariantReview>> getProductReviews(String productId) async {
    try {
      // Fetch reviews from remote (no local caching)
      final remoteReviews = await _remoteDataSource.getProductReviews(
        productId,
      );
      return remoteReviews.map((e) => e.toDomain()).toList();
    } catch (e) {
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
      // Check remote (no local caching)
      return await _remoteDataSource.isInWishlist(productId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> addToWishlist(String productId) async {
    try {
      // Add to remote (no local caching)
      await _remoteDataSource.addToWishlist(productId);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> removeFromWishlist(String productId) async {
    try {
      // Remove from remote (no local caching)
      await _remoteDataSource.removeFromWishlist(productId);
    } catch (e) {
      rethrow;
    }
  }
}
