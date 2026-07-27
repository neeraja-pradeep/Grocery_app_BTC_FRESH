// lib/features/home/presentation/components/product_card.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/network/socket_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../cart/infrastructure/data_sources/remote/checkout_line_data_source.dart';
import '../../../auth/application/states/auth_state.dart';
import '../../../cart/application/providers/checkout_line_provider.dart';
import '../../../category/application/providers/inventory_update_notifier.dart';
import '../../../category/application/providers/price_update_notifier.dart';
import '../../../wishlist/application/providers/wishlist_provider.dart';
import '../../domain/entities/product_variant.dart';

class ProductCard extends ConsumerStatefulWidget {
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
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  @override
  void initState() {
    super.initState();
    // Join Socket.IO room for this product variant
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(socketServiceProvider).joinVariantRoom(widget.product.id);
      }
    });
  }

  Future<void> _handleDecreaseQuantity(int lineId) async {
    try {
      await ref
          .read(checkoutLineControllerProvider.notifier)
          .updateQuantity(lineId: lineId, delta: -1);
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(context, 'Unable to update cart');
      }
    }
  }

  Future<void> _handleIncreaseQuantity(int lineId) async {
    try {
      await ref
          .read(checkoutLineControllerProvider.notifier)
          .updateQuantity(lineId: lineId, delta: 1);
    } catch (_) {
      if (mounted) {
        AppSnackbar.error(context, 'Unable to update cart');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;

    // Watch real-time Socket.IO updates
    final priceUpdates = ref.watch(priceUpdateNotifierProvider);
    final inventoryUpdates = ref.watch(inventoryUpdateNotifierProvider);

    // Get real-time price and inventory updates
    final priceEvent = priceUpdates.getUpdate(product.id);
    final inventoryEvent = inventoryUpdates.getUpdate(product.id);

    // Determine display prices: use Socket.IO real-time if available
    final double displayPrice =
        priceEvent?.newPrice ??
        (product.hasDiscount ? product.discountedPrice! : product.price);
    final double? originalPrice =
        priceEvent?.oldPrice ?? (product.hasDiscount ? product.price : null);

    // Stock status from real-time inventory
    final currentQuantity = inventoryEvent?.currentQuantity;
    final inStock = currentQuantity != null
        ? currentQuantity > 0
        : product.inStock;

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
          onTap: widget.onTap,
          child: Opacity(
            opacity: inStock ? 1.0 : 0.45,
            child: Container(
            width: widget.width.w,
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
                                memCacheWidth: 360,
                                maxWidthDiskCache: 1080,
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
                                  '₹${displayPrice.toStringAsFixed(0)}', // Current Price (real-time)
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: priceColor,
                                  ),
                                ),
                                if (originalPrice != null && originalPrice > 0)
                                  Text(
                                    '₹${originalPrice.toStringAsFixed(0)}', // Old Price (real-time)
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      decoration: TextDecoration.lineThrough,
                                      color: Colors.grey,
                                    ),
                                  ),
                                // Real-time update indicator
                                if (priceEvent != null ||
                                    inventoryEvent != null)
                                  Icon(
                                    Icons.circle,
                                    size: 8.sp,
                                    color: Colors.blue,
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
        ),

        // --- Floating Add Button (+) / Quantity Selector ---
        Positioned(
          top: -8.h, // Overlaps the top border
          right: -8.w, // Overlaps the right border
          child: Consumer(
            builder: (context, ref, child) {
              // Selected down to this card's own line, so an unrelated cart
              // change (or the 30s cart poll) does not rebuild every card in
              // the list.
              final cartLine = ref.watch(
                checkoutLineControllerProvider.select((state) {
                  for (final item in state.items) {
                    if (item.productVariantId == product.id) {
                      return (id: item.id, quantity: item.quantity);
                    }
                  }
                  return null;
                }),
              );

              if (cartLine != null) {
                final lineId = cartLine.id;
                final quantity = cartLine.quantity;
                return _QuantitySelector(
                  quantity: quantity,
                  borderColor: borderColor,
                  iconColor: iconColor,
                  onDecrease: () => _handleDecreaseQuantity(lineId),
                  onIncrease: () => _handleIncreaseQuantity(lineId),
                );
              }

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

                  // Check if product is in stock (use real-time data)
                  if (!inStock) {
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
                  } on InsufficientStockException catch (e) {
                    if (context.mounted) {
                      AppSnackbar.warning(context, e.message);
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
                    border: Border.all(
                      color: inStock ? borderColor : Colors.grey,
                      width: 1.2.w,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    color: inStock ? iconColor : Colors.grey,
                    size: 20.sp,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Compact horizontal quantity selector ( -  qty  + ) shown in place of the
/// floating add button once the product is in the cart. Matches the look of
/// the home `ProductCard` add button: white pill with green border.
class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.borderColor,
    required this.iconColor,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final Color borderColor;
  final Color iconColor;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: borderColor, width: 1.2.w),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDecrease,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 28.w,
              height: 34.h,
              child: Icon(Icons.remove, color: iconColor, size: 18.sp),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              quantity.toString(),
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          GestureDetector(
            onTap: onIncrease,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 28.w,
              height: 34.h,
              child: Icon(Icons.add, color: iconColor, size: 18.sp),
            ),
          ),
        ],
      ),
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
    // Primary path: combine numeric weight + unit from the API
    // (e.g. weight="200.00" + unit="units"  ->  "200 units").
    final number = _normalizeWeightNumber(weight);
    final unitRaw =
        (stockUnit != null && stockUnit!.trim().isNotEmpty && stockUnit != 'null')
            ? stockUnit!.trim()
            : null;

    if (number != null && unitRaw != null) {
      return _formatWeight('$number $unitRaw');
    }
    if (unitRaw != null) {
      return _formatWeight(unitRaw);
    }
    if (number != null) {
      return number;
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

  /// Parses the raw `weight` field (e.g. "200.00", "1.25", "0") and returns
  /// a cleaned-up numeric string ("200", "1.25"). Returns null for missing,
  /// zero, or unparseable values so the caller can fall back.
  String? _normalizeWeightNumber(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final value = double.tryParse(trimmed);
    if (value == null || value <= 0) return null;
    if (value % 1 == 0) return value.toInt().toString();
    return value
        .toString()
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
}
