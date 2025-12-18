class CategoryProduct {
  const CategoryProduct({
    required this.id,
    required this.name,
    required this.variantId,
    required this.variantName,
    this.variantSku,
    this.description,
    this.slug,
    this.price,
    this.originalPrice,
    this.weight,
    this.rating,
    this.imageUrl,
    this.thumbnailUrl,
    this.categoryId,
    this.defaultVariantId,
    this.currentQuantity,
    this.status,
  });

  final String id;
  final String name;
  final String variantId;
  final String variantName;
  final String? variantSku;
  final String? description;
  final String? slug;
  final String? price;
  final String? originalPrice;
  final String? weight;
  final double? rating;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? categoryId;
  final String? defaultVariantId;
  final int? currentQuantity;
  final bool? status;

  /// Check if product is in stock based on API data
  bool get inStock {
    // If we have currentQuantity, check if > 0
    if (currentQuantity != null) {
      return currentQuantity! > 0;
    }
    // If we have status field, use it
    if (status != null) {
      return status!;
    }
    // Default to true if no stock info (backend will validate)
    return true;
  }
}
