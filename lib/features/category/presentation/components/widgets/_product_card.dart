import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/network/socket_provider.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../cart/application/providers/checkout_line_provider.dart';
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
  Future<void> _handleAddToCart(BuildContext context) async {
    // Also call the parent callback for any additional behavior
    widget.onAddToCart();

    // Add to cart via API
    if (variantId > 0) {
      try {
        await ref
            .read(checkoutLineControllerProvider.notifier)
            .addToCart(productVariantId: variantId, quantity: 1);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${widget.product.variantName} added to cart'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add to cart: $e'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final image = widget.product.imageUrl ?? widget.product.thumbnailUrl;
    final formattedWeight = _formatWeight(widget.product.weight);

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

    // Stock status from real-time inventory
    final inStock = (inventoryEvent?.currentQuantity ?? 0) > 0;
    final quantity = inventoryEvent?.currentQuantity ?? 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: AppColors.grey.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: widget.colorScheme.shadow.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 4),
              // jnkjbn
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
                    top: 8.h,
                    right: 5.w,
                    child: _AnimatedAddButton(
                      onTap: () => _handleAddToCart(context),
                      primaryColor: widget.colorScheme.primary,
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
                      Icon(
                        Icons.favorite_border,
                        size: 22.sp,
                        color: isDark
                            ? widget.colorScheme.outline
                            : AppColors.green100,
                      ),
                    ],
                  ),
                  // Stock status indicator - shown below price
                  if (inventoryEvent != null) ...[
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
                            ? quantity > 10
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
        color: AppColors.green10,
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
  const _AnimatedAddButton({required this.onTap, required this.primaryColor});

  final VoidCallback onTap;
  final Color primaryColor;

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
            child: Container(
              width: 29.w,
              height: 29.w,
              decoration: BoxDecoration(
                color: widget.primaryColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white.withValues(
                    alpha: _glowAnimation.value * 0.8,
                  ),
                  width: 2.5 * _glowAnimation.value,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(
                      alpha: 0.3 + (_glowAnimation.value * 0.4),
                    ),
                    blurRadius: 4 + (_glowAnimation.value * 8),
                    spreadRadius: _glowAnimation.value * 2,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.add, color: AppColors.white, size: 20),
            ),
          );
        },
      ),
    );
  }
}
