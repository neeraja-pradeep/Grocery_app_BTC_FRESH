import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/network/socket_provider.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../auth/application/providers/auth_provider.dart';
import '../../../../auth/application/states/auth_state.dart';
import '../../../../cart/application/providers/checkout_line_provider.dart';
import '../../../../cart/infrastructure/data_sources/remote/checkout_line_data_source.dart';
import '../../../../wishlist/application/providers/wishlist_provider.dart';
import '../../../application/providers/inventory_update_notifier.dart';
import '../../../application/providers/price_update_notifier.dart';
import '../../../domain/entities/category_product.dart';

const String _rupeeSymbol = '\u20B9';

/// Individual product card displayed in product grid
/// Shows: Image + add-to-cart button | Name, weight, price + wishlist + real-time Socket.IO updates
/// Tap card to view product details
/// Features real-time price and inventory updates via Socket.IO

class ProductCard extends ConsumerStatefulWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.colorScheme,
    required this.onAddToCart,
    this.onTap,
  });

  final CategoryProduct product;
  final ColorScheme colorScheme;
  final VoidCallback onAddToCart;
  final VoidCallback? onTap;

  @override
  ConsumerState<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<ProductCard> {
  late int variantId;

  @override
  void initState() {
    super.initState();
    // Parse variant ID and join Socket.IO room
    variantId = int.tryParse(widget.product.variantId) ?? 0;

    if (variantId > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Check if widget is still mounted before using ref
        // The callback may fire after the widget is disposed
        if (mounted) {
          ref.read(socketServiceProvider).joinVariantRoom(variantId);
        }
      });
    }
  }

  /// Handle add to cart with backend integration
  Future<void> _handleAddToCart(BuildContext context, bool inStock) async {
    // Check if product is in stock before adding
    if (!inStock) {
      if (context.mounted) {
        AppSnackbar.warning(context, 'This product is out of stock');
      }
      return;
    }

    // Block guests from adding to cart
    final authState = ref.read(authProvider);
    final isGuest = authState is GuestMode;

    if (isGuest) {
      AppSnackbar.info(context, 'Please login to add items to cart');
      return;
    }

    // Also call the parent callback for any additional behavior
    widget.onAddToCart();

    // Add to cart via API
    if (variantId > 0) {
      try {
        await ref
            .read(checkoutLineControllerProvider.notifier)
            .addToCart(productVariantId: variantId, quantity: 1);
        // Don't show success notification
      } on InsufficientStockException catch (e) {
        if (context.mounted) {
          AppSnackbar.warning(context, e.message);
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.error(context, 'Failed to add to cart');
        }
      }
    }
  }

  /// Handle decrease quantity or remove from cart
  Future<void> _handleDecreaseQuantity(BuildContext context, int lineId) async {
    if (variantId > 0) {
      try {
        await ref
            .read(checkoutLineControllerProvider.notifier)
            .updateQuantity(lineId: lineId, delta: -1);
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.error(context, 'Failed to update cart');
        }
      }
    }
  }

  /// Handle increase quantity in cart
  Future<void> _handleIncreaseQuantity(BuildContext context, int lineId) async {
    if (variantId > 0) {
      try {
        await ref
            .read(checkoutLineControllerProvider.notifier)
            .updateQuantity(lineId: lineId, delta: 1);
      } catch (e) {
        if (context.mounted) {
          AppSnackbar.error(context, 'Failed to update cart');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = widget.product.imageUrl ?? widget.product.thumbnailUrl;
    final formattedWeight = _formatWeight(widget.product.weight);

    // Watch cart state to check if product is in cart
    final cartState = ref.watch(checkoutLineControllerProvider);
    final cartItem = cartState.items.where(
      (item) => item.productVariantId == variantId,
    );
    final isInCart = cartItem.isNotEmpty;
    final cartLineId = isInCart ? cartItem.first.id : 0;
    final cartQuantity = isInCart ? cartItem.first.quantity : 0;

    // Watch real-time Socket.IO updates
    final priceUpdates = ref.watch(priceUpdateNotifierProvider);
    final inventoryUpdates = ref.watch(inventoryUpdateNotifierProvider);

    // Get real-time price event if available
    final priceEvent = variantId > 0 ? priceUpdates.getUpdate(variantId) : null;
    final inventoryEvent = variantId > 0
        ? inventoryUpdates.getUpdate(variantId)
        : null;

    // Determine display prices: use Socket.IO real-time if available
    final displayPrice = priceEvent?.newPrice != null
        ? priceEvent!.newPrice.toStringAsFixed(2)
        : widget.product.price;
    final displayOriginalPrice = priceEvent?.oldPrice != null
        ? priceEvent!.oldPrice!.toStringAsFixed(2)
        : widget.product.originalPrice;

    final priceValue = _formatPriceValue(displayPrice);
    final originalPriceValue = _formatPriceValue(displayOriginalPrice);

    // Stock status: prefer real-time Socket.IO data, fallback to API data
    final socketQuantity = inventoryEvent?.currentQuantity;
    final hasSocketData = socketQuantity != null;
    // Use socket data if available, otherwise use API data from product entity
    final currentQuantity = socketQuantity ?? widget.product.currentQuantity;
    // Check stock: socket data > API data > default to product.inStock
    final inStock = hasSocketData ? socketQuantity > 0 : widget.product.inStock;
    final quantity = currentQuantity ?? 0;

    // Show stock badge if we have real-time socket data or API stock data
    final showStockBadge =
        hasSocketData || widget.product.currentQuantity != null;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: 171.h,
        width: 129.w,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.grey.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: widget.colorScheme.shadow.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(10.r),
                        ),
                        color: AppColors.white,
                      ),
                      child: ClipRRect(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _ProductImage(image: image),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4.h,
                    right: 4.w,
                    child: isInCart
                        ? _QuantitySelector(
                            quantity: cartQuantity,
                            onDecrease: () =>
                                _handleDecreaseQuantity(context, cartLineId),
                            onIncrease: () =>
                                _handleIncreaseQuantity(context, cartLineId),
                          )
                        : _AnimatedAddButton(
                            onTap: () => _handleAddToCart(context, inStock),
                            primaryColor: inStock
                                ? AppColors.green
                                : AppColors.grey,
                            isEnabled: inStock,
                          ),
                  ),
                  // Real-time update indicator
                  if (priceEvent != null || inventoryEvent != null)
                    Positioned(
                      top: 8.h,
                      left: 5.w,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.sync,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.pageTitle(
                    text: widget.product.variantName,
                    maxLines: 1,
                  ),

                  AppSpacing.h8,
                  if (formattedWeight != null)
                    AppText(
                      text: formattedWeight,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey,
                    ),
                  if (formattedWeight != null) AppSpacing.h8,
                  // Price row with wishlist icon
                  Row(
                    children: [
                      if (priceValue != null) ...[
                        const AppText.pageTitle(text: _rupeeSymbol),
                        AppSpacing.w4,
                        AppText.pageTitle(text: priceValue),
                        if (originalPriceValue != null &&
                            originalPriceValue != priceValue) ...[
                          AppSpacing.w8,
                          AppText(
                            text: '$_rupeeSymbol$originalPriceValue',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: AppColors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ],
                      ] else ...[
                        const AppText.pageTitle(text: 'N/A'),
                      ],
                      const Spacer(),
                      Consumer(
                        builder: (context, ref, child) {
                          final isInWishlist = ref.watch(
                            isInWishlistProvider(widget.product.variantId),
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
                              final success = await wishlistNotifier
                                  .toggleWishlist(widget.product.variantId);
                              if (context.mounted && success) {
                                AppSnackbar.success(
                                  context,
                                  isInWishlist
                                      ? 'Removed from wishlist'
                                      : 'Added to wishlist',
                                );
                              }
                            },
                            child: Icon(
                              isInWishlist
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 22.sp,
                              color: isInWishlist
                                  ? Colors.red
                                  : AppColors.green100,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  // Stock status indicator - shown below price
                  if (showStockBadge) ...[
                    AppSpacing.h4,
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: inStock
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: AppText(
                        text: inStock
                            ? quantity > 0
                                  ? 'In Stock'
                                  : 'Only $quantity left'
                            : 'Out of Stock',
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w600,
                        color: inStock ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Product image with fallback handling (local/network/placeholder)

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.image});

  final String? image;

  @override
  Widget build(BuildContext context) {
    if (image == null || image!.isEmpty) {
      return Container(
        color: const Color.fromARGB(189, 239, 244, 235),
        alignment: Alignment.center,
        child: const Icon(
          Icons.local_grocery_store_outlined,
          size: 28,
          color: AppColors.green100,
        ),
      );
    }

    if (image!.startsWith('assets/')) {
      return Image.asset(image!, fit: BoxFit.cover);
    }

    return Image(
      image: NetworkImage(image!, headers: {'User-Agent': 'Mozilla/5.0'}),
      fit: BoxFit.fitHeight,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.green10,
        alignment: Alignment.center,
        child: const Icon(
          Icons.broken_image_outlined,
          size: 28,
          color: AppColors.green100,
        ),
      ),
    );
  }
}

String? _formatWeight(String? weight) {
  if (weight == null) return null;

  final trimmed = weight.trim();
  if (trimmed.isEmpty) return null;

  final numeric = double.tryParse(trimmed);
  if (numeric != null) {
    final value = numeric % 1 == 0
        ? numeric.toInt().toString()
        : _trimTrailingZeros(numeric.toStringAsFixed(2));
    return '$value g';
  }

  final hasUnit = RegExp(r'[A-Za-z]').hasMatch(trimmed);
  if (hasUnit) {
    return trimmed;
  }

  return '$trimmed g';
}

String? _formatPriceValue(String? price) {
  if (price == null) return null;

  final trimmed = price.trim();
  if (trimmed.isEmpty) return null;

  var normalized = trimmed;
  if (normalized.startsWith(_rupeeSymbol)) {
    normalized = normalized.substring(_rupeeSymbol.length).trim();
  }

  if (normalized.isEmpty) return null;
  if (normalized.toUpperCase() == 'N/A') return null;

  final numeric = double.tryParse(normalized.replaceAll(',', ''));
  if (numeric != null) {
    return numeric % 1 == 0
        ? numeric.toInt().toString()
        : _trimTrailingZeros(numeric.toStringAsFixed(2));
  }

  return normalized;
}

String _trimTrailingZeros(String value) {
  return value.replaceFirst(RegExp(r'\.?0+$'), '');
}

/// Animated add-to-cart button with highlight effect
class _AnimatedAddButton extends StatefulWidget {
  const _AnimatedAddButton({
    required this.onTap,
    required this.primaryColor,
    this.isEnabled = true,
  });

  final VoidCallback onTap;
  final Color primaryColor;
  final bool isEnabled;

  @override
  State<_AnimatedAddButton> createState() => _AnimatedAddButtonState();
}

class _AnimatedAddButtonState extends State<_AnimatedAddButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isEnabled) return;
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: widget.isEnabled ? 1.0 : 0.5,
              child: Container(
                width: 29.w,
                height: 29.w,
                decoration: BoxDecoration(
                  color: widget.primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white.withValues(
                      alpha: widget.isEnabled
                          ? _glowAnimation.value * 0.8
                          : 0.3,
                    ),
                    width:
                        2.5 * (widget.isEnabled ? _glowAnimation.value : 0.5),
                  ),
                  boxShadow: widget.isEnabled
                      ? [
                          BoxShadow(
                            color: widget.primaryColor.withValues(
                              alpha: 0.3 + (_glowAnimation.value * 0.4),
                            ),
                            blurRadius: 4 + (_glowAnimation.value * 8),
                            spreadRadius: _glowAnimation.value * 2,
                          ),
                        ]
                      : [],
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.add, color: AppColors.white, size: 20),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Simple horizontal quantity selector [-] [qty] [+]
class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 29.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus button
          GestureDetector(
            onTap: onDecrease,
            child: Container(
              width: 29.w,
              height: 29.h,
              decoration: const BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.remove, color: AppColors.white, size: 18),
            ),
          ),
          // Quantity display
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: AppText(
              text: quantity.toString(),
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          // Plus button
          GestureDetector(
            onTap: onIncrease,
            child: Container(
              width: 29.w,
              height: 29.h,
              decoration: const BoxDecoration(
                color: AppColors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}
