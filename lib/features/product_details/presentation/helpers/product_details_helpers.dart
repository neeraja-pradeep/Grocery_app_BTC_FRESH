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
  final int parsedId = int.tryParse(product.id) ?? 0;
  final List<ProductVariantMedia> media = [];
  final String thumbnailUrl = ensureHttpsUrl(product.thumbnailUrl);

  if (thumbnailUrl.isNotEmpty) {
    media.add(
      ProductVariantMedia(
        id: 1,
        filePath: thumbnailUrl,
        image: thumbnailUrl,
        alt: '${product.name} Thumbnail',
        productId: parsedId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  final String imageUrl = ensureHttpsUrl(product.imageUrl);

  return ProductVariant(
    id: parsedId,
    sku: product.id,
    name: product.name,
    variantName: product.variantName,
    productId: parsedId,
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

/// Parse weight string and normalize to gm or kg
///
/// Examples: "500 gm" -> "500 gm", "1000 gm" -> "1 kg", "1200 gm" -> "1.2 kg"
String parseWeight(String weight) {
  try {
    final cleanedWeight = weight.trim().toLowerCase();
    final regex = RegExp(r'([\d.]+)\s*([a-z]*)');
    final match = regex.firstMatch(cleanedWeight);
    if (match == null) return weight;

    final numericValue = double.tryParse(match.group(1) ?? '0') ?? 0;
    final unit = (match.group(2) ?? '').replaceAll(RegExp(r'[^a-z]'), '');

    double valueInGrams = numericValue;
    if (unit.contains('k')) {
      valueInGrams = numericValue * 1000;
    }

    if (valueInGrams >= 1000) {
      final valueInKg = valueInGrams / 1000;
      final formatted = valueInKg.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
      return '$formatted kg';
    } else {
      final formatted = valueInGrams.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
      return '$formatted gm';
    }
  } catch (_) {
    return weight;
  }
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
