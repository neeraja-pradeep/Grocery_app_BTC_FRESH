import 'package:hive_flutter/hive_flutter.dart';
import '../../models/product_variant_dto.dart';
import './product_detail_cache_dto.dart';

/// Local data source for caching product details.
///
/// This uses Hive for persistent storage with two-tier caching:
/// 1. Basic cache: Just the product data (ProductVariantDto)
/// 2. Full cache with metadata: Includes Last-Modified and eTag headers
///
/// For the last-modified update system, ALWAYS use the metadata methods:
/// - getCachedProductDetail() → Read with lastModified
/// - cacheProductDetailWithMetadata() → Save with lastModified
///
/// The metadata (lastModified, eTag) is essential for conditional requests:
/// - If-Modified-Since header uses lastModified value
/// - If-None-Match header uses eTag value
/// - Server compares these with its data to return 304 or 200
abstract class ProductDetailLocalDataSource {
  /// Get cached product detail (basic data only, no metadata).
  ///
  /// Use this if you only need the product data without cache headers.
  /// For the last-modified system, use getCachedProductDetail() instead.
  Future<ProductVariantDto?> getProductDetail(String productId);

  /// Cache product detail (basic data only, no metadata).
  ///
  /// Use this if you only need to cache product data without headers.
  /// For the last-modified system, use cacheProductDetailWithMetadata() instead.
  Future<void> cacheProductDetail(String productId, ProductVariantDto detail);

  /// Get cached product detail WITH Last-Modified and eTag metadata.
  ///
  /// This returns:
  /// - productDetail: The actual product data
  /// - lastSyncedAt: When we last checked (used for TTL)
  /// - lastModified: HTTP Last-Modified header (for If-Modified-Since)
  /// - eTag: HTTP ETag header (for If-None-Match)
  ///
  /// This metadata is CRITICAL for the last-modified update system.
  /// The repository uses it to construct conditional request headers.
  Future<ProductDetailCacheDto?> getCachedProductDetail(String productId);

  /// Cache product detail WITH Last-Modified and eTag metadata.
  ///
  /// This saves:
  /// - productDetail: The actual product data
  /// - lastSyncedAt: Current timestamp (sets TTL)
  /// - lastModified: From HTTP response header (for next If-Modified-Since)
  /// - eTag: From HTTP response header (for next If-None-Match)
  ///
  /// ALWAYS use this for the last-modified update system.
  /// It ensures lastModified is stored and will be used in the next poll.
  Future<void> cacheProductDetailWithMetadata(
    String productId,
    ProductDetailCacheDto cacheDto,
  );

  /// Clear cached product detail.
  ///
  /// Removes both the product data and its metadata from Hive.
  Future<void> clearProductDetail(String productId);

  /// Get cached reviews
  Future<List<ProductVariantReviewDto>?> getProductReviews(String productId);

  /// Cache product reviews
  Future<void> cacheProductReviews(
    String productId,
    List<ProductVariantReviewDto> reviews,
  );

  /// Check if product is in local wishlist
  Future<bool> isInWishlist(String productId);

  /// Add to local wishlist cache
  Future<void> addToWishlist(String productId);

  /// Remove from local wishlist cache
  Future<void> removeFromWishlist(String productId);
}

/// Implementation using Hive
class ProductDetailLocalDataSourceImpl implements ProductDetailLocalDataSource {
  ProductDetailLocalDataSourceImpl(this._box);

  final Box<dynamic> _box;

  static const String _productDetailPrefix = 'product_detail_';
  static const String _productReviewPrefix = 'product_reviews_';
  static const String _wishlistKey = 'wishlist_items';

  @override
  Future<ProductVariantDto?> getProductDetail(String productId) async {
    try {
      final key = '$_productDetailPrefix$productId';
      final json = _box.get(key) as Map<String, dynamic>?;
      return json != null ? ProductVariantDto.fromJson(json) : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheProductDetail(
    String productId,
    ProductVariantDto detail,
  ) async {
    try {
      final key = '$_productDetailPrefix$productId';
      await _box.put(key, detail.toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<ProductDetailCacheDto?> getCachedProductDetail(
    String productId,
  ) async {
    try {
      final key = '${_productDetailPrefix}metadata_$productId';
      final json = _box.get(key) as Map<String, dynamic>?;
      return json != null ? ProductDetailCacheDto.fromJson(json) : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheProductDetailWithMetadata(
    String productId,
    ProductDetailCacheDto cacheDto,
  ) async {
    try {
      final key = '${_productDetailPrefix}metadata_$productId';
      await _box.put(key, cacheDto.toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> clearProductDetail(String productId) async {
    try {
      final key = '$_productDetailPrefix$productId';
      final metadataKey = '${_productDetailPrefix}metadata_$productId';
      await _box.delete(key);
      await _box.delete(metadataKey);
    } catch (e) {
      rethrow;
    }
  }

  /// Clear all cached product details
  Future<void> clearAllCache() async {
    try {
      final keys = _box.keys.toList();
      for (final key in keys) {
        if (key.toString().startsWith(_productDetailPrefix)) {
          await _box.delete(key);
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ProductVariantReviewDto>?> getProductReviews(
    String productId,
  ) async {
    try {
      final key = '$_productReviewPrefix$productId';
      final jsonList = _box.get(key) as List<dynamic>?;
      return jsonList
          ?.map(
            (e) => ProductVariantReviewDto.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheProductReviews(
    String productId,
    List<ProductVariantReviewDto> reviews,
  ) async {
    try {
      final key = '$_productReviewPrefix$productId';
      final jsonList = reviews.map((e) => e.toJson()).toList();
      await _box.put(key, jsonList);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> isInWishlist(String productId) async {
    try {
      final wishlist = _box.get(_wishlistKey) as List<dynamic>? ?? [];
      return wishlist.contains(productId);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> addToWishlist(String productId) async {
    try {
      final wishlist = _box.get(_wishlistKey) as List<dynamic>? ?? [];
      if (!wishlist.contains(productId)) {
        wishlist.add(productId);
        await _box.put(_wishlistKey, wishlist);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> removeFromWishlist(String productId) async {
    try {
      final wishlist = _box.get(_wishlistKey) as List<dynamic>? ?? [];
      wishlist.removeWhere((item) => item == productId);
      await _box.put(_wishlistKey, wishlist);
    } catch (e) {
      rethrow;
    }
  }
}
