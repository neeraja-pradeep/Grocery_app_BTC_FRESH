import '../entities/product_variant.dart';

/// Abstract repository for product details
/// Defines contract for fetching detailed product information
abstract class ProductDetailRepository {
  /// Fetch product detail by product ID
  /// Throws NetworkException or other exceptions
  Future<ProductVariant> getProductDetail(String productId);

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
