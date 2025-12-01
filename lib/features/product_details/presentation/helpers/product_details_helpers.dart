import '../../../category/domain/entities/category_product.dart';
import '../../domain/entities/product_variant.dart';

/// Utility functions for Product Details feature
/// Handles data conversion and validation logic

/// Convert CategoryProduct to ProductVariant for UI compatibility
///
/// This provides fallback data when API hasn't fetched full product details.
/// Useful for initial screen render before Riverpod state updates.
///
/// - Converts category product to variant format
/// - Creates media items from thumbnail/image URLs
/// - Ensures HTTPS protocol on all URLs
ProductVariant convertToProductVariant(CategoryProduct product) {
  final List<ProductVariantMedia> media = [];
  final String thumbnailUrl = ensureHttpsUrl(product.thumbnailUrl);

  if (thumbnailUrl.isNotEmpty) {
    media.add(
      ProductVariantMedia(
        id: 1,
        filePath: thumbnailUrl,
        image: thumbnailUrl,
        alt: '${product.name} Thumbnail',
        productId: int.parse(product.id),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  final String imageUrl = ensureHttpsUrl(product.imageUrl);

  return ProductVariant(
    id: int.parse(product.id),
    sku: product.id,
    name: product.name,
    variantName: product.variantName,
    productId: int.parse(product.id),
    trackInventory: false,
    price: product.price ?? '0',
    originalPrice: product.originalPrice,
    weight: product.weight,
    rating: product.rating,
    imageUrl: imageUrl.isNotEmpty ? product.imageUrl : null,
    thumbnailUrl: thumbnailUrl.isNotEmpty ? thumbnailUrl : null,
    media: media.isNotEmpty ? media : null,
    categoryId: product.categoryId,
    description: product.description,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

/// Ensure image URL has https:// protocol
///
/// If URL is null or empty, returns empty string.
/// If URL already has http:// or https://, returns as-is.
/// Otherwise, prepends https:// to the URL.
String ensureHttpsUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) {
    return url;
  }
  return 'https://$url';
}

/// Extract numeric price from price string
///
/// Removes all non-numeric characters except decimal point.
/// Returns 0.0 if parsing fails.
///
/// Examples:
/// - '₹500' -> 500.0
/// - '1200.50' -> 1200.50
/// - 'invalid' -> 0.0
double extractNumericPrice(String priceString) {
  return double.tryParse(priceString.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
}
