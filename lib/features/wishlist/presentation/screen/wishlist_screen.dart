// lib/features/wishlist/presentation/screen/wishlist_screen.dart

// ignore_for_file: prefer_const_constructors, unused_import, no_leading_underscores_for_local_identifiers, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_app/features/wishlist/application/providers/wishlist_provider.dart';
import 'package:new_app/features/wishlist/domain/entities/wishlist_item.dart';

// Assuming these imports are available for correct functionality/casting
// import 'package:new_app/features/home/domain/entities/product.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'My Wishlist',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: wishlistState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : wishlistState.hasError
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${wishlistState.error}'),
                  ElevatedButton(
                    onPressed: () =>
                        ref.read(wishlistProvider.notifier).loadWishlist(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : wishlistState.items.isEmpty
          ? SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.only(top: 80.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.favorite_border,
                      size: 100,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your wishlist is empty',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Add items to your wishlist to see them here',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 40),
                    // Show banner even when empty
                    WishlistBanner(),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing:
                                10, // Adjusted for typical spacing
                            mainAxisSpacing: 10, // Adjusted for typical spacing
                            childAspectRatio: 0.75,
                          ),
                      itemCount: wishlistState.items.length,
                      itemBuilder: (context, index) {
                        return WishlistProductCard(
                          item: wishlistState.items[index],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  WishlistBanner(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }
}

// ---------------------------------------------------
// Wishlist Banner (Placeholder)
// ---------------------------------------------------

class WishlistBanner extends StatelessWidget {
  const WishlistBanner({super.key});

  @override
  Widget build(BuildContext context) {
    // Colors and Text styles matching image_acdf14.png
    const Color bannerBgColor = Color(0xFFE8F5E9);
    const Color buttonColor = Color(0xFF66BB6A);
    const TextStyle titleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800, // Slightly bolder for impact
      height: 1.2, // Tighter line height
      color: Colors.black,
    );
    const TextStyle subtitleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      height: 1.2,
      color: Colors.black,
    );

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 12.0,
      ), // Matches grid padding
      height: 177,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bannerBgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Text and Button Content
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('World Food Festival,', style: titleStyle),
                const Text('Bring the world to', style: subtitleStyle),
                const Text('your Kitchen!', style: subtitleStyle),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => {
                    // Navigate to shop/home screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24, // Wider padding
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Shop Now',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Placeholder Image (positioned to the right)
          Positioned(
            right: 0,
            bottom: 0,
            top: 0, // Fill vertical space
            child: SizedBox(
              width: 150, // Dedicate fixed width for the image
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                // Using a placeholder Image.asset - ensure 'assets/images/banner_products.png' exists
                child: Image.asset(
                  'assets/images/banner_products.png',
                  fit: BoxFit.cover, // Cover mode to fill the dedicated width
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback in case image asset is missing
                    return Container(
                      color: Colors.grey.shade300,
                      child: Center(
                        child: Icon(
                          Icons.fastfood,
                          size: 50,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------
// Component 3: WishlistProductCard (Updated positioning for Plus icon)
// ---------------------------------------------------
class WishlistProductCard extends ConsumerWidget {
  final WishlistItem item;

  const WishlistProductCard({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Convert WishlistItem to Product for consistent styling
    final product = item.toProduct();

    return Stack(
      clipBehavior: Clip.none, // Allow children to overflow
      children: [
        // Main card container
        Container(
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
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Expanded(
                  flex: 4,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: product.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              product.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
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
                const SizedBox(height: 12),
                // Product Name
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    fontFamily: 'Poppins',
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Unit Label (same as ProductCard)
                Text(
                  item.unitLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Poppins',
                    color: Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                // Price and Weight Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Price Column
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '₹${item.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(width: 6),
                            if (item.mrp > item.price)
                              Text(
                                '₹${item.mrp.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                          ],
                        ),
                        // Weight/Unit information (moved to top, same as ProductCard)
                        const SizedBox(height: 2),
                      ],
                    ),
                    // Heart icon (Remove from Wishlist) - moved to bottom right
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(wishlistProvider.notifier)
                            .removeFromWishlist(item.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${item.name} removed from wishlist'),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.red, // Red color like ProductCard
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Plus icon (Add to Cart) - positioned at top right corner
        Positioned(
          top: -12,
          right: -12,
          child: GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add to cart tapped (dummy)')),
              );
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Color(0xFF4CAF50), size: 20),
            ),
          ),
        ),
      ],
    );
  }
}
