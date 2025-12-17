// lib/features/home/presentation/components/product_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../auth/application/states/auth_state.dart';
import '../../../cart/application/providers/checkout_line_provider.dart';
import '../../../wishlist/application/providers/wishlist_provider.dart';
import '../../domain/entities/product_variant.dart';

class ProductCard extends ConsumerWidget {
  final ProductVariant product;
  final VoidCallback onTap;
  final double width;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.width = 150,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? imageUrl = product.mainImageUrl;

    // // Debug: Print product info
    // print('ProductCard - Product: ${product.name}');
    // print('ProductCard - Media count: ${product.media.length}');
    // print('ProductCard - Image URL: $imageUrl');

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
            width: width.w,
            decoration: BoxDecoration(
              color: cardBgColor, // Everything else is green
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Padding(
              padding: EdgeInsets.all(4.w),
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
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.all(8.w),
                      child: Center(
                        child: imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.contain,
                                placeholder: (context, url) => Center(
                                  child: SizedBox(
                                    height: 20.h,
                                    width: 20.w,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.w,
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
                            : Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                                size: 40.sp,
                              ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // 2. Product Name - Fixed height for 2 lines
                  SizedBox(
                    height: 12.sp * 1.2 * 2, // fontSize * lineHeight * 2 lines
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600, // Semi-bold
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                  ),

                  SizedBox(height: 6.h),

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
                            // Price Row - Wrap to prevent overflow
                            Wrap(
                              spacing: 4.w,
                              runSpacing: 2.h,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  '₹${product.hasDiscount ? product.discountedPrice?.toStringAsFixed(0) : product.price.toStringAsFixed(0)}', // Current Price
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: priceColor,
                                  ),
                                ),
                                if (product.hasDiscount)
                                  Text(
                                    '₹${product.price.toStringAsFixed(0)}', // Old Price
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 2.h),
                            // Weight
                            Text(
                              product.displayWeight,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
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
                              // Block guests from adding to wishlist
                              final authState = ref.read(authProvider);
                              final isGuest = authState is GuestMode;

                              if (isGuest) {
                                AppSnackbar.info(
                                  context,
                                  'Please login to add items to wishlist',
                                );
                                return;
                              }

                              final wishlistNotifier = ref.read(
                                wishlistProvider.notifier,
                              );
                              await wishlistNotifier.toggleWishlist(
                                product.id.toString(),
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 2.h),
                              child: Icon(
                                isInWishlist
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: isInWishlist
                                    ? Colors.red
                                    : const Color(0xFF00897B),
                                size: 22.sp,
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
          top: -8.h, // Overlaps the top border
          right: -8.w, // Overlaps the right border
          child: Consumer(
            builder: (context, ref, child) {
              return GestureDetector(
                onTap: () async {
                  // Block guests from adding to cart
                  final authState = ref.read(authProvider);
                  final isGuest = authState is GuestMode;

                  if (isGuest) {
                    AppSnackbar.info(
                      context,
                      'Please login to add items to cart',
                    );
                    return;
                  }

                  // Check if product is in stock
                  if (!product.inStock) {
                    if (context.mounted) {
                      AppSnackbar.warning(
                        context,
                        'This product is out of stock',
                      );
                    }
                    return;
                  }

                  try {
                    await ref
                        .read(checkoutLineControllerProvider.notifier)
                        .addToCart(productVariantId: product.id, quantity: 1);
                    if (context.mounted) {
                      AppSnackbar.success(
                        context,
                        '${product.name} added to cart',
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppSnackbar.error(context, 'Unable to add item to cart');
                    }
                  }
                },
                child: Container(
                  width: 34.w,
                  height: 34.h,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: borderColor, width: 1.2.w),
                  ),
                  child: Icon(Icons.add, color: iconColor, size: 20.sp),
                ),
              );
            },
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

  String get displayWeight {
    // Enhanced weight parsing with multiple fallback strategies
    if (stockUnit != null && stockUnit!.isNotEmpty && stockUnit != 'null') {
      final cleaned = stockUnit!.trim();
      if (cleaned.isNotEmpty) {
        return _formatWeight(cleaned);
      }
    }

    // Fallback strategies based on product name analysis
    final productName = name.toLowerCase();

    // Common weight patterns in product names
    final weightPatterns = [
      RegExp(
        r'(\d+(?:\.\d+)?)\s*(kg|g|gm|gram|grams|kilogram|kilograms)',
        caseSensitive: false,
      ),
      RegExp(
        r'(\d+(?:\.\d+)?)\s*(ml|l|ltr|litre|litres|millilitre)',
        caseSensitive: false,
      ),
      RegExp(r'(\d+(?:\.\d+)?)\s*(piece|pieces|pcs|pc)', caseSensitive: false),
    ];

    for (final pattern in weightPatterns) {
      final match = pattern.firstMatch(productName);
      if (match != null) {
        final value = match.group(1);
        final unit = match.group(2);
        return _formatWeight('$value $unit');
      }
    }

    // Category-based intelligent defaults
    if (productName.contains('oil') || productName.contains('ghee')) {
      return '500 ml';
    } else if (productName.contains('rice') ||
        productName.contains('flour') ||
        productName.contains('dal')) {
      return '1 kg';
    } else if (productName.contains('spice') ||
        productName.contains('masala')) {
      return '100 g';
    } else if (productName.contains('biscuit') ||
        productName.contains('cookie')) {
      return '200 g';
    } else if (productName.contains('milk') || productName.contains('juice')) {
      return '1 L';
    } else if (productName.contains('bread') || productName.contains('roti')) {
      return '400 g';
    }

    // Final fallback based on price range
    if (price < 50) {
      return '100 g';
    } else if (price < 200) {
      return '250 g';
    } else if (price < 500) {
      return '500 g';
    } else {
      return '1 kg';
    }
  }

  String _formatWeight(String weight) {
    // Normalize common weight formats
    final normalized = weight
        .toLowerCase()
        .replaceAll('gm', 'g')
        .replaceAll('gram', 'g')
        .replaceAll('grams', 'g')
        .replaceAll('kilogram', 'kg')
        .replaceAll('kilograms', 'kg')
        .replaceAll('millilitre', 'ml')
        .replaceAll('litre', 'l')
        .replaceAll('litres', 'l')
        .replaceAll('ltr', 'l')
        .replaceAll('piece', 'pc')
        .replaceAll('pieces', 'pcs')
        .trim();

    // Ensure proper spacing
    return normalized.replaceAllMapped(
      RegExp(r'(\d+(?:\.\d+)?)([a-z]+)'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
  }
}
