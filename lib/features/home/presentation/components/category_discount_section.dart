import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/network/socket_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../auth/application/states/auth_state.dart';
import '../../../cart/application/providers/checkout_line_provider.dart';
import '../../../cart/infrastructure/data_sources/remote/checkout_line_data_source.dart';
import '../../../category/application/providers/inventory_update_notifier.dart';
import '../../../category/application/providers/price_update_notifier.dart';
import '../../domain/entities/category_discount_group.dart';
import '../../domain/entities/product_variant.dart';

class CategoryDiscountSection extends StatelessWidget {
  final CategoryDiscountGroup group;
  final ValueChanged<ProductVariant> onProductClick;
  final ValueChanged<ProductVariant> onAddToCart;

  const CategoryDiscountSection({
    super.key,
    required this.group,
    required this.onProductClick,
    required this.onAddToCart,
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
                onAddToCart: () {
                  onAddToCart(product);
                  Logger.debug(
                    'Add to cart clicked',
                    data: {
                      'product_id': product.id,
                      'product_name': product.name,
                    },
                  );
                },
              );
            },
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

class MegaOfferProductCard extends ConsumerStatefulWidget {
  final ProductVariant product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const MegaOfferProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  ConsumerState<MegaOfferProductCard> createState() =>
      _MegaOfferProductCardState();
}

class _MegaOfferProductCardState extends ConsumerState<MegaOfferProductCard> {
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
    final bool hasDiscount =
        originalPrice != null && originalPrice > displayPrice;

    // Format discount text
    final String discountPercentage = hasDiscount
        ? '${(((originalPrice - displayPrice) / originalPrice) * 100).round()}%'
        : '';

    return GestureDetector(
      onTap: widget.onTap,
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
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.h,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red, // Red background like image
                            borderRadius: BorderRadius.all(
                              Radius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            '-$discountPercentage',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // 3. Add Button (Bottom Right of Image)
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () async {
                        // Check if product is in stock
                        if (!inStock) {
                          if (context.mounted) {
                            AppSnackbar.warning(
                              context,
                              'This product is out of stock',
                            );
                          }
                          return;
                        }

                        // Block guests from adding to cart
                        final authState = ref.read(authProvider);
                        final isGuest = authState is GuestMode;

                        if (isGuest) {
                          if (context.mounted) {
                            AppSnackbar.info(
                              context,
                              'Please login to add items to cart',
                            );
                          }
                          return;
                        }

                        // Add to cart via API
                        try {
                          await ref
                              .read(checkoutLineControllerProvider.notifier)
                              .addToCart(
                                productVariantId: product.id,
                                quantity: 1,
                              );
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
                            AppSnackbar.error(
                              context,
                              'Unable to add item to cart',
                            );
                          }
                        }

                        // Also call the parent callback
                        widget.onAddToCart();
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: inStock
                              ? null
                              : Border.all(color: Colors.grey, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.add,
                          color: inStock
                              ? const Color(0xFF4CAF50)
                              : Colors.grey,
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
                        // Current Price (Green) - No Rs symbol (real-time)
                        Text(
                          displayPrice.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4CAF50), // Green
                            height: 1.0,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        // Old Price (Strikethrough) - No Rs symbol (real-time)
                        if (hasDiscount)
                          Text(
                            originalPrice.toStringAsFixed(2),
                            style: TextStyle(
                              fontSize: 10.sp,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[400],
                            ),
                          ),
                        // Real-time update indicator
                        if (priceEvent != null || inventoryEvent != null) ...[
                          SizedBox(width: 4.w),
                          Icon(Icons.circle, size: 6.sp, color: Colors.blue),
                        ],
                      ],
                    ),

                    SizedBox(height: 4.h),

                    // 2. Product Name
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),

                    const Spacer(),

                    // 3. Price per kg (e.g., "3,45 / kg")
                    Text(
                      '${product.pricePerKg} / kg',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                      ),
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

  String get pricePerKg {
    // Use discounted price if available, otherwise use regular price
    final effectivePrice = hasDiscount ? (discountedPrice ?? price) : price;
    return effectivePrice.toStringAsFixed(2).replaceAll('.', ',');
  }

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
