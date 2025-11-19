import '../../domain/entities/product_detail.dart';
import '../../domain/repositories/product_detail_repository.dart';
import '../data_sources/local/product_detail_local_data_source.dart';
import '../data_sources/remote/product_detail_remote_data_source.dart';

/// Implementation of ProductDetailRepository
/// Combines local cache and remote API with fallback strategy
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

  @override
  Future<ProductDetail> getProductDetail(String productId) async {
    try {
      // Try to fetch from remote first
      final remoteDetail = await _remoteDataSource.getProductDetail(productId);

      // Cache the result
      await _localDataSource.cacheProductDetail(productId, remoteDetail);

      return remoteDetail.toDomain();
    } catch (e) {
      // Fallback to local cache on error
      final cachedDetail = await _localDataSource.getProductDetail(productId);
      if (cachedDetail != null) {
        return cachedDetail.toDomain();
      }
      rethrow;
    }
  }

  @override
  Future<List<ProductReview>> getProductReviews(String productId) async {
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
