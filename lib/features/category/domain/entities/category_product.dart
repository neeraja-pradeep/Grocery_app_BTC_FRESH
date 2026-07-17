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
    this.unit,
    this.rating,
    this.imageUrl,
    this.thumbnailUrl,
    this.categoryId,
    this.defaultVariantId,
    this.currentQuantity,
    this.status,
    this.apiInStock,
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
  // Backend `unit` value attached to the variant (e.g. "g", "kg", "pack",
  // "units"). Rendered alongside `weight` on the product card.
  final String? unit;
  final double? rating;
  final String? imageUrl;
  final String? thumbnailUrl;
  final String? categoryId;
  final String? defaultVariantId;
  final int? currentQuantity;
  final bool? status;

  /// Variant-level `in_stock` boolean from the products list response.
  /// Authoritative when present; falls back to `currentQuantity` then to
  /// "assume in stock" when both are absent.
  final bool? apiInStock;

  /// Check if product is in stock based on API data.
  /// Priority: explicit `in_stock` flag > `currentQuantity > 0` > default true.
  /// `status` is the product's active/published flag, not stock availability,
  /// so it is intentionally not consulted here.
  bool get inStock {
    if (apiInStock != null) return apiInStock!;
    if (currentQuantity != null) return currentQuantity! > 0;
    // No stock info — assume in stock; backend will validate on add-to-cart.
    return true;
  }
}
