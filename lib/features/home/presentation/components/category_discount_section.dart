import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/entities/category_discount_group.dart';
import '../../domain/entities/product_variant.dart';

class CategoryDiscountSection extends StatelessWidget {
  final CategoryDiscountGroup group;
  final ValueChanged<ProductVariant> onProductClick;

  const CategoryDiscountSection({
    super.key,
    required this.group,
    required this.onProductClick,
  });

  @override
  Widget build(BuildContext context) {
    if (!group.shouldDisplay) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Name
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Text(
            group.category.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xff576780),
            ),
          ),
        ),

        // Products Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              // Adjusted aspect ratio to fit the vertical layout of the card
              childAspectRatio: 0.55,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: group.displayList.length > 6
                ? 6
                : group.displayList.length,
            itemBuilder: (context, index) {
              final product = group.displayList[index];
              return MegaOfferProductCard(
                product: product,
                onTap: () => onProductClick(product),
              );
            },
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

class MegaOfferProductCard extends StatelessWidget {
  final ProductVariant product;
  final VoidCallback onTap;

  const MegaOfferProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = product.mainImageUrl;
    final bool hasDiscount = product.hasDiscount;

    // Format discount text
    final String discountPercentage = hasDiscount
        ? '${(((product.price - (product.discountedPrice ?? product.price)) / product.price) * 100).round()}%'
        : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        // Removed border to match the clean look of the image
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          // Very subtle shadow for depth, or remove if you want completely flat
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- TOP: Image Stack ---
            Expanded(
              flex: 5, // Image takes up about 60% of vertical space
              child: Stack(
                children: [
                  // 1. The Product Image
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Center(
                      child: imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.contain,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            )
                          : const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 30,
                            ),
                    ),
                  ),

                  // 2. Discount Badge (Top Right)
                  if (hasDiscount)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: const BoxDecoration(
                          color: Colors.red, // Red background like image
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(12),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          '-$discountPercentage',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // 3. Add Button (Bottom Right of Image)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        // Handle Add to Cart
                        // print("Added ${product.name} to cart");
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Color(0xFF4CAF50), // Green Plus
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- BOTTOM: Text Info ---
            Expanded(
              flex: 3, // Text takes remaining space
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    // 1. Price Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Current Price (Green)
                        Text(
                          hasDiscount
                              ? '₹${product.discountedPrice?.toStringAsFixed(2)}'
                              : '₹${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50), // Green
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Old Price (Strikethrough)
                        if (hasDiscount)
                          Text(
                            product.price.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 10,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[400],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // 2. Product Name
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),

                    const Spacer(),

                    // 3. Unit / Weight (e.g., "1 kg" or "3.45 / kg")
                    Text(
                      product.weight ?? 'per unit',
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Extension to get product properties safely
extension ProductVariantMegaOffer on ProductVariant {
  String? get mainImageUrl {
    if (media.isNotEmpty) {
      return media.first.imageUrl;
    }
    return null;
  }

  bool get hasDiscount => discountedPrice != null && discountedPrice! < price;

  String? get weight {
    // Debug logging to understand what's in stockUnit
    Logger.debug(
      'Product weight debug',
      data: {
        'product_name': name,
        'stock_unit': stockUnit ?? 'null',
        'current_quantity': currentQuantity,
        'product_id': id,
      },
    );

    if (stockUnit != null && stockUnit!.isNotEmpty) {
      return stockUnit;
    }

    // Try to extract weight from product name if it contains weight info
    final nameWeight = _extractWeightFromName(name);
    if (nameWeight != null) {
      return nameWeight;
    }

    // Try to use currentQuantity if it contains unit info
    if (currentQuantity.isNotEmpty && currentQuantity != '0') {
      // Check if currentQuantity contains unit information
      final quantityWithUnit = _parseQuantityWithUnit(currentQuantity);
      if (quantityWithUnit != null) {
        return quantityWithUnit;
      }
    }

    // Fallback based on product category or type
    return _getDefaultWeight();
  }

  String? _extractWeightFromName(String productName) {
    // Common weight patterns in product names
    final weightPatterns = [
      RegExp(
        r'(\d+(?:\.\d+)?)\s*(kg|g|ml|l|litre|liter|gram|kilogram)',
        caseSensitive: false,
      ),
      RegExp(r'(\d+(?:\.\d+)?)\s*(pack|pcs|pieces)', caseSensitive: false),
    ];

    for (final pattern in weightPatterns) {
      final match = pattern.firstMatch(productName);
      if (match != null) {
        return '${match.group(1)} ${match.group(2)}';
      }
    }
    return null;
  }

  String? _parseQuantityWithUnit(String quantity) {
    // Check if quantity already contains unit info
    if (RegExp(
      r'\d+\s*(kg|g|ml|l|pack|pcs)',
      caseSensitive: false,
    ).hasMatch(quantity)) {
      return quantity;
    }
    return null;
  }

  String _getDefaultWeight() {
    // Provide sensible defaults based on product name
    final lowerName = name.toLowerCase();

    if (lowerName.contains('milk') || lowerName.contains('juice')) {
      return '1 L';
    } else if (lowerName.contains('oil') || lowerName.contains('ghee')) {
      return '1 L';
    } else if (lowerName.contains('rice') ||
        lowerName.contains('flour') ||
        lowerName.contains('sugar')) {
      return '1 kg';
    } else if (lowerName.contains('bread') || lowerName.contains('biscuit')) {
      return '1 pack';
    } else {
      return '1 unit';
    }
  }
}
