// lib/features/wishlist/presentation/screen/wishlist_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:new_app/features/home/domain/entities/product_variant.dart';
import 'package:new_app/features/home/presentation/components/advertisement_card.dart';
import 'package:new_app/features/home/application/providers/home_provider.dart';
import 'package:new_app/features/wishlist/application/providers/wishlist_provider.dart';
import 'package:new_app/features/wishlist/domain/entities/wishlist_item.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistState = ref.watch(wishlistProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Color(0xFFcaf5ac), // Custom green color
        statusBarIconBrightness: Brightness.dark, // Dark icons
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'My Wishlist',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
        body: wishlistState.when(
          initial: () => const Center(child: CircularProgressIndicator()),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (failure, _) => Center(child: Text('Error: $failure')),
          refreshing: (items) => _buildContent(context, ref, items),
          loaded: (items, _) => _buildContent(context, ref, items),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<WishlistItem> items,
  ) {
    if (items.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          children: [
            // Product Grid with matching UI from product_horizontal_list
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.68, // Adjusted to match card proportions
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final wishlistItem = items[index];
                final productVariant = wishlistItem.toProductVariant();
                return WishlistProductCard(
                  product: productVariant,
                  wishlistItem: wishlistItem,
                  onTap: () => _handleProductTap(context, productVariant),
                  ref: ref,
                );
              },
            ),

            const SizedBox(height: 24),

            // Advertisement Banner
            Consumer(
              builder: (context, ref, child) {
                final activeAd = ref.watch(activeAdProvider);
                if (activeAd != null) {
                  return AdvertisementCard(
                    banner: activeAd,
                    onShopNowClick: () => _handleShopNowClick(context),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Your wishlist is empty',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Consumer(
              builder: (context, ref, child) {
                final activeAd = ref.watch(activeAdProvider);
                if (activeAd != null) {
                  return AdvertisementCard(
                    banner: activeAd,
                    onShopNowClick: () => _handleShopNowClick(context),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleProductTap(BuildContext context, ProductVariant product) {
    Navigator.pushNamed(
      context,
      '/product-details',
      arguments: {'productId': product.productId, 'variantId': product.id},
    );
  }

  void _handleShopNowClick(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

// Wishlist Product Card matching the style from product_horizontal_list.dart
class WishlistProductCard extends StatelessWidget {
  final ProductVariant product;
  final WishlistItem wishlistItem;
  final VoidCallback onTap;
  final WidgetRef ref;

  const WishlistProductCard({
    super.key,
    required this.product,
    required this.wishlistItem,
    required this.onTap,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    // Use imageUrl from wishlistItem if available, otherwise from product
    final String imageUrl = wishlistItem.imageUrl.isNotEmpty
        ? wishlistItem.imageUrl
        : (product.media.isNotEmpty ? product.media.first.imageUrl : '');

    // Colors matching product_horizontal_list.dart
    const Color borderColor = Color(0xFF8cc727);
    const Color cardBgColor = Color(0xFFe4fad5);
    const Color iconColor = Color(0xFF00695C);
    const Color priceColor = Color(0xFF2E7D32);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Card Content
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: cardBgColor,
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: imageUrl.isNotEmpty
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
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 3. Bottom Section: Price/Weight + Heart
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
                                  "₹${product.hasDiscount ? product.discountedPrice?.toStringAsFixed(0) : product.price.toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: priceColor,
                                  ),
                                ),
                                if (product.hasDiscount) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    "₹${product.price.toStringAsFixed(0)}",
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
                              wishlistItem.unitLabel.isNotEmpty
                                  ? wishlistItem.unitLabel
                                  : (product.stockUnit ?? "80 g"),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Right Side: Heart Icon (filled since it's in wishlist)
                      GestureDetector(
                        onTap: () async {
                          final wishlistNotifier = ref.read(
                            wishlistProvider.notifier,
                          );
                          await wishlistNotifier.toggleWishlist(
                            product.id.toString(),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(bottom: 2),
                          child: Icon(
                            Icons.favorite_rounded,
                            color: Colors.red,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Floating Add Button (+)
        Positioned(
          top: -8,
          right: -8,
          child: GestureDetector(
            onTap: () {
              // Add to cart logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.name} added to cart'),
                  duration: const Duration(seconds: 2),
                ),
              );
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
