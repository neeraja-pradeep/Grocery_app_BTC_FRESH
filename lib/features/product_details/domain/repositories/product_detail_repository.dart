import '../entities/product_variant.dart';
import '../entities/product_base.dart';

/// Abstract repository for product details
/// Defines contract for fetching detailed product information
abstract class ProductDetailRepository {
  /// Fetch product variant detail by variant ID
  ///
  /// Returns:
  /// - ProductVariant: Server returned 200 OK (data changed, UI will refresh)
  /// - null: Server returned 304 Not Modified (no change, use cached data)
  ///
  /// [forceRefresh] bypasses cache TTL and forces a fresh API request.
  /// Throws NetworkException or other exceptions
  Future<ProductVariant?> getProductDetail(
    String variantId, {
    bool forceRefresh = false,
  });

  /// Fetch product base data by product ID
  ///
  /// Returns:
  /// - ProductBase: Server returned 200 OK (new data, UI will refresh)
  /// - null: Server returned 304 Not Modified (no change, use cached data)
  ///
  /// [forceRefresh] bypasses cache TTL and forces a fresh API request.
  /// Throws NetworkException or other exceptions
  Future<ProductBase?> getProductBase(
    String productId, {
    bool forceRefresh = false,
  });

  /// Fetch product reviews by product ID
  /// Throws NetworkException or other exceptions
  Future<List<ProductVariantReview>> getProductReviews(String productId);

  /// Fetch product variant by variant ID
  /// Throws NetworkException or other exceptions
  Future<ProductVariant> getProductVariant(String variantId);

  /// Check if product is in wishlist
  Future<bool> isInWishlist(String productId);

  /// Add product to wishlist
  Future<void> addToWishlist(String productId);

  /// Remove product from wishlist
  Future<void> removeFromWishlist(String productId);
}
