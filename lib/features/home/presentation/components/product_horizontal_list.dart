import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:new_app/features/home/domain/entities/product_variant.dart';
import 'package:new_app/features/wishlist/application/providers/wishlist_provider.dart';

class ProductHorizontalList extends ConsumerWidget {
  final List<ProductVariant> products;
  final ValueChanged<ProductVariant> onProductClick;

  const ProductHorizontalList({
    super.key,
    required this.products,
    required this.onProductClick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 240, // Adjusted height to fit all new details (weight, prices)
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        // Vertical padding ensures the floating "+" button isn't cut off
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        clipBehavior: Clip.none,
        itemCount: products.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ProductCard(
              product: products[index],
              onTap: () => onProductClick(products[index]),
              width: 150,
              ref: ref,
            ),
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final ProductVariant product;
  final VoidCallback onTap;
  final double width;
  final WidgetRef ref;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.width,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = product.mainImageUrl;

    // Colors extracted from your reference image
    const Color borderColor = Color(0xFF8cc727);
    const Color cardBgColor = Color(0xFFe4fad5);
    const Color iconColor = Color(0xFF00695C);
    const Color priceColor = Color(0xFF2E7D32);

    return Stack(
      clipBehavior: Clip.none, // Allows the plus button to float outside
      children: [
        // --- Main Card Content ---
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: cardBgColor, // Everything else is green
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Image Section with WHITE Background
                  Expanded(
                    flex: 5,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors
                            .white, // Explicitly requested white background
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8.0),
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
                                      color: iconColor,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                              )
                            : const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 40,
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 2. Product Name
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600, // Semi-bold
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 3. Bottom Section: Price/Weight (Left) + Heart (Right)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Left Side: Prices and Weight
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Price Row
                            Row(
                              children: [
                                Text(
                                  "₹${product.hasDiscount ? product.discountedPrice?.toStringAsFixed(0) : product.price.toStringAsFixed(0)}", // Current Price
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: priceColor,
                                  ),
                                ),
                                if (product.hasDiscount) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    "₹${product.price.toStringAsFixed(0)}", // Old Price
                                    style: const TextStyle(
                                      fontSize: 11,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            // Weight
                            Text(
                              product.weight ?? " g",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right Side: Heart Icon
                      Consumer(
                        builder: (context, ref, child) {
                          final isInWishlist = ref.watch(
                            isInWishlistProvider(product.id.toString()),
                          );

                          return GestureDetector(
                            onTap: () async {
                              final wishlistNotifier = ref.read(
                                wishlistProvider.notifier,
                              );
                              await wishlistNotifier.toggleWishlist(
                                product.id.toString(),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Icon(
                                isInWishlist
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isInWishlist
                                    ? Colors.red
                                    : const Color(0xFF00897B),
                                size: 22,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // --- Floating Add Button (+) ---
        Positioned(
          top: -10, // Overlaps the top border
          right: -10, // Overlaps the right border
          child: GestureDetector(
            onTap: () {
              // Add to cart logic
            },
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: const Icon(Icons.add, color: iconColor, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

// Helper extension (Ensure this is accessible in your file)
extension ProductVariantDisplay on ProductVariant {
  String? get mainImageUrl {
    if (media.isNotEmpty) {
      return media.first.imageUrl;
    }
    return null;
  }

  bool get hasDiscount => discountedPrice != null && discountedPrice! < price;

  String? get weight {
    if (stockUnit != null && stockUnit!.isNotEmpty) {
      return stockUnit;
    }
    // Default logic if stockUnit is missing
    return "80 g";
  }
}
