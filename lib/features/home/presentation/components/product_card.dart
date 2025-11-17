// features/home/presentation/components/product_card.dart

// ignore_for_file: avoid_print, prefer_const_constructors, no_leading_underscores_for_local_identifiers

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_app/features/home/domain/entities/category.dart';
// <<< IMPORT REAL ENTITIES for static typing
import 'package:new_app/features/home/domain/entities/product.dart';
import 'package:new_app/features/home/domain/entities/offer.dart';
import 'package:new_app/features/wishlist/application/providers/wishlist_provider.dart';
import 'package:new_app/features/home/presentation/screen/category_detail_screen.dart';

// ------------------------------------------

/// A standard product card used in horizontal strips (e.g., Best Deals).
class ProductCard extends ConsumerWidget {
  final Product product; // <<< CHANGED from dynamic to Product

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistNotifier = ref.read(wishlistProvider.notifier);
    final wishlistState = ref.watch(wishlistProvider);
    final isInWishlist = wishlistState.isInWishlist(product.id.toString());

    return GestureDetector(
      onTap: () => {
        // Handle product tap, e.g., navigate to product detail
      },
      child: Stack(
        clipBehavior: Clip.none, // Allows children to overflow
        children: [
          Container(
            width: 150,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xffe4fad5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: product.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // print(
                                //   'Image load error for ${product.name}: $error',
                                // );
                                return const Icon(
                                  Icons.image_not_supported,
                                  size: 40,
                                  color: Colors.grey,
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                        strokeWidth: 2,
                                      ),
                                    );
                                  },
                            ),
                          )
                        : const Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Colors.grey,
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                // Product Name
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Unit Label
                Text(
                  product.unitLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                // Price Row
                Row(
                  children: [
                    Text(
                      '₹${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (product.mrp > product.price)
                      Text(
                        '₹${product.mrp.toStringAsFixed(0)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                          fontSize: 10,
                          fontFamily: 'Poppins',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Plus icon (dummy for now)
          Positioned(
            top: -10, // Adjust this value to control how much it pokes out
            right: -5, // Adjust this value to control how much it pokes out
            child: GestureDetector(
              onTap: () {
                // Dummy action for the plus icon
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Plus icon tapped (dummy)')),
                );
              },
              child: Container(
                width:
                    36, // Slightly larger for better visibility when poking out
                height: 36,
                decoration: BoxDecoration(
                  color:
                      Colors.white, // Always green as it's a dummy add button
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 24),
              ),
            ),
          ),
          // Wishlist Heart Icon at bottom right
          Positioned(
            bottom: 10,
            right: 20,
            child: GestureDetector(
              onTap: () async {
                try {
                  if (isInWishlist) {
                    // Show "already added" message instead of removing
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Already added to wishlist'),
                        ),
                      );
                    }
                  } else {
                    await wishlistNotifier.addToWishlist(product.id.toString());
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to wishlist'),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },

              child: Icon(
                isInWishlist ? Icons.favorite : Icons.favorite_border,
                color: isInWishlist ? Colors.red : Colors.red,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A specialized card for the Mega Offers section.
/// A specialized card for the Mega Offers section.
// features/home/presentation/components/product_card.dart

// ... (other classes and imports remain the same)

/// A specialized card for the Mega Offers section.
class MegaOfferProductCard extends ConsumerWidget {
  final Offer product; // <<< CHANGED from dynamic to Offer

  const MegaOfferProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistNotifier = ref.read(wishlistProvider.notifier);
    final wishlistState = ref.watch(wishlistProvider);
    final isInWishlist = wishlistState.isInWishlist(product.id.toString());

    // Determine the discount percentage
    final double discount = (product.oldPrice > product.price)
        ? ((product.oldPrice - product.price) / product.oldPrice) * 100
        : 0;

    // --- New Color/Style Definitions to Match Image ---
    const Color newPriceColor = Color(0xFF4CAF50); // Green color from image
    const Color addButtonColor = Color(0xFF4CAF50); // Green color for plus icon

    return Container(
      width: 120, // FIX 1: Increased width from 100 to 120 to prevent overflow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Main Product Content
          Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Product Image
                Container(
                  height: 70,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xFFF7F7F7),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: product.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            product.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Colors.grey.shade400,
                                  size: 30,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value:
                                      loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: Colors.grey.shade400,
                            size: 30,
                          ),
                        ),
                ),
                const SizedBox(height: 8),

                // 2. Prices
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      // Price display (Green, comma decimal)
                      product.price.toStringAsFixed(2).replaceAll('.', ','),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14, // FIX 2: Reduced font size from 16 to 14
                        color: newPriceColor, // Green price
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(
                      width: 2,
                    ), // FIX 3: Reduced space from 4 to 2
                    Text(
                      // Old price display (Strikethrough, comma decimal)
                      product.oldPrice.toStringAsFixed(2).replaceAll('.', ','),
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                        fontSize: 10, // FIX 2: Reduced font size from 12 to 10
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // 3. Name and Weight
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                // Note: Assuming Offer has a 'weight' field.
                Text(
                  product.weight,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),

          // 4. Discount Badge (Top Right of Image Area)
          if (discount > 0)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                ),
                child: Text(
                  '-${discount.round()}%',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // 5. Add to Wishlist Button (Bottom Right of Image Area)
          Positioned(
            top: 55,
            right: 12,
            child: GestureDetector(
              onTap: () async {
                try {
                  if (isInWishlist) {
                    // Show "already added" message instead of removing
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Already added to wishlist'),
                        ),
                      );
                    }
                  } else {
                    await wishlistNotifier.addToWishlist(product.id.toString());
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to wishlist'),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(
                  isInWishlist ? Icons.favorite : Icons.favorite_border,
                  color: isInWishlist ? Colors.red : addButtonColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CategoryItemCard extends StatelessWidget {
  final Category category;

  const CategoryItemCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigation logic from original _CategoryCard
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailScreen(category: category),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Category Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  color: Colors.grey.shade50,
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: category.iconUrl.isNotEmpty == true
                      ? Image.network(
                          category.iconUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.category,
                              size: 40,
                              color: Colors.green,
                            );
                          },
                        )
                      : const Icon(
                          Icons.category,
                          size: 40,
                          color: Colors.green,
                        ),
                ),
              ),
            ),
            // Category Name
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
