import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:new_app/features/home/domain/entities/product_variant.dart';

class ProductHorizontalList extends StatelessWidget {
  final List<ProductVariant> products;
  final ValueChanged<ProductVariant> onProductClick;

  const ProductHorizontalList({
    super.key,
    required this.products,
    required this.onProductClick,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240, // Reduced height to fit the compact design
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ProductCard(
              product: products[index],
              onTap: () => onProductClick(products[index]),
              width: 150, // Slightly narrower to match reference aspect ratio
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

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = product.mainImageUrl;

    return Stack(
      children: [
        // Main Card Content
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: width,
            decoration: BoxDecoration(
              // Very light green background
              color: const Color(0xFFF1F8E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFAED581), // Softer green border
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16), // Space for the top button area
                  // Image Section - Transparent background (Removed white box)
                  Expanded(
                    flex: 5,
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
                                    color: Color(0xFF4CAF50),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 40,
                              ),
                            )
                          : const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 40,
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Product Name
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Price Section
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (product.hasDiscount) ...[
                        Text(
                          "₹ ${product.discountedPrice?.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32), // Dark green
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "₹${product.price.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey[600],
                          ),
                        ),
                      ] else
                        Text(
                          "₹ ${product.price.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32), // Dark green
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),

        // Add Button (+) - Positioned top right, inside the border
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              // TODO: Add to cart functionality
              // print("Added to cart: ${product.name}");
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                // Rounded only on top-right and bottom-left to blend or standard radius
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(11), // Matches card radius
                  bottomLeft: Radius.circular(12),
                ),
                border: Border(
                  left: BorderSide(
                    color: const Color(0xFFAED581).withValues(alpha: 0.5),
                  ),
                  bottom: BorderSide(
                    color: const Color(0xFFAED581).withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: const Icon(Icons.add, color: Color(0xFF2E7D32), size: 22),
            ),
          ),
        ),
      ],
    );
  }
}

// Helper extension
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
    return "500g";
  }
}
