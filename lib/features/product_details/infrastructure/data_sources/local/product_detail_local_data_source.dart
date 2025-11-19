import 'package:hive_flutter/hive_flutter.dart';
import '../../models/product_detail_dto.dart';

/// Local data source for caching product details
abstract class ProductDetailLocalDataSource {
  /// Get cached product detail
  Future<ProductDetailDto?> getProductDetail(String productId);

  /// Cache product detail
  Future<void> cacheProductDetail(String productId, ProductDetailDto detail);

  /// Clear cached product detail
  Future<void> clearProductDetail(String productId);

  /// Get cached reviews
  Future<List<ProductReviewDto>?> getProductReviews(String productId);

  /// Cache product reviews
  Future<void> cacheProductReviews(
    String productId,
    List<ProductReviewDto> reviews,
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
  Future<ProductDetailDto?> getProductDetail(String productId) async {
    try {
      final key = '$_productDetailPrefix$productId';
      final json = _box.get(key) as Map<String, dynamic>?;
      return json != null ? ProductDetailDto.fromJson(json) : null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheProductDetail(
    String productId,
    ProductDetailDto detail,
  ) async {
    try {
      final key = '$_productDetailPrefix$productId';
      await _box.put(key, detail.toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> clearProductDetail(String productId) async {
    try {
      final key = '$_productDetailPrefix$productId';
      await _box.delete(key);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ProductReviewDto>?> getProductReviews(String productId) async {
    try {
      final key = '$_productReviewPrefix$productId';
      final jsonList = _box.get(key) as List<dynamic>?;
      return jsonList
          ?.map((e) => ProductReviewDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheProductReviews(
    String productId,
    List<ProductReviewDto> reviews,
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
