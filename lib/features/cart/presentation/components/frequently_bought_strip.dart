import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../auth/application/states/auth_state.dart';
import '../../application/providers/checkout_line_provider.dart';
import '../../application/providers/frequently_bought_provider.dart';
import '../../domain/entities/checkout_line.dart';
import '../../domain/entities/frequently_bought_item.dart';
import '../../../../core/widgets/app_network_image.dart';

const Color _kBadgeRed = Color(0xFFE81F2B);
const Color _kImageBg = Color(0xFFD6EEDD);
const Color _kQtyAccent = Color(0xFF34A853); // icon color in white boxes
const Color _kQtyBoxGreen = Color(0xFF84C318); // background of the qty box

/// Horizontally scrollable "Frequently Bought" section shown under the cart
/// items list. Silent on empty / error / guest, so it never adds visual noise.
class FrequentlyBoughtStrip extends ConsumerWidget {
  const FrequentlyBoughtStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is GuestMode) {
      return const SizedBox.shrink();
    }

    final async = ref.watch(frequentlyBoughtProvider);
    return async.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return _StripBody(items: items);
      },
    );
  }
}

class _StripBody extends StatelessWidget {
  const _StripBody({required this.items});

  final List<FrequentlyBoughtItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: 'Frequently Bought',
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
          SizedBox(height: 12.h),
          SizedBox(
            height: 222.34.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, _) => SizedBox(width: 12.w),
              itemBuilder: (context, index) =>
                  _FrequentlyBoughtCard(item: items[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _FrequentlyBoughtCard extends ConsumerWidget {
  const _FrequentlyBoughtCard({required this.item});

  final FrequentlyBoughtItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final variant = item.variant;

    // Resolve current cart line for this variant (so the strip card stays in
    // sync with the live cart list above it).
    final cartState = ref.watch(checkoutLineControllerProvider);
    CheckoutLine? existingLine;
    for (final line in cartState.items) {
      if (line.productVariantId == variant.id) {
        existingLine = line;
        break;
      }
    }
    final cartQuantity = existingLine?.quantity ?? 0;
    final inStock = variant.inStock;

    return SizedBox(
      width: 128.91.w,
      height: 222.34.h,
      child: Opacity(
        opacity: inStock ? 1.0 : 0.5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ImageArea(
              variant: variant,
              cartQuantity: cartQuantity,
              existingLineId: existingLine?.id,
              inStock: inStock,
            ),
            SizedBox(height: 14.06.h),
            _NameAndPrice(variant: variant),
          ],
        ),
      ),
    );
  }
}

class _ImageArea extends ConsumerWidget {
  const _ImageArea({
    required this.variant,
    required this.cartQuantity,
    required this.existingLineId,
    required this.inStock,
  });

  final FrequentlyBoughtVariant variant;
  final int cartQuantity;
  final int? existingLineId;
  final bool inStock;

  Future<void> _handleAdd(BuildContext context, WidgetRef ref) async {
    if (!inStock) {
      AppSnackbar.warning(context, 'This product is out of stock');
      return;
    }
    try {
      await ref
          .read(checkoutLineControllerProvider.notifier)
          .addToCart(productVariantId: variant.id, quantity: 1);
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Failed to add to cart');
      }
    }
  }

  Future<void> _handleDecrement(BuildContext context, WidgetRef ref) async {
    final lineId = existingLineId;
    if (lineId == null) return; // nothing to decrement
    try {
      await ref
          .read(checkoutLineControllerProvider.notifier)
          .updateQuantity(lineId: lineId, delta: -1);
    } catch (_) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Failed to update cart');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 128.91.w,
      height: 128.91.w,
      decoration: BoxDecoration(
        color: _kImageBg,
        borderRadius: BorderRadius.circular(7.03.r),
      ),
      child: Stack(
        children: [
          // Product image
          Positioned(
            left: 11.w,
            top: 38.76.h,
            child: SizedBox(
              width: 106.w,
              height: 66.47.h,
              child: _ProductImageView(imageUrl: variant.imageUrl),
            ),
          ),

          // Discount badge
          if (variant.hasDiscount)
            Positioned(
              top: 5.h,
              left: 82.w,
              child: Container(
                width: 42.w,
                height: 19.h,
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: _kBadgeRed,
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: AppText(
                  text: '${variant.discountPercentage}%',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),

          // Quantity controls.
          // When nothing in cart: a single white "+" box sits at left:96.
          // When in cart: three separate boxes — "-" (white) at left:6,
          // quantity (green #84C318) at left:38, "+" (white) at left:96.
          if (cartQuantity == 0)
            Positioned(
              left: 96.w,
              top: 96.h,
              child: _IconBox(
                icon: Icons.add,
                enabled: inStock,
                onTap: () => _handleAdd(context, ref),
              ),
            )
          else ...[
            Positioned(
              left: 6.w,
              top: 96.h,
              child: _IconBox(
                icon: Icons.remove,
                enabled: true,
                onTap: () => _handleDecrement(context, ref),
              ),
            ),
            Positioned(
              left: 38.w,
              top: 96.h,
              child: _QtyDisplay(quantity: cartQuantity),
            ),
            Positioned(
              left: 96.w,
              top: 96.h,
              child: _IconBox(
                icon: Icons.add,
                enabled: inStock,
                onTap: () => _handleAdd(context, ref),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductImageView extends StatelessWidget {
  const _ProductImageView({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return const Center(
        child: Icon(Icons.shopping_basket_outlined, color: AppColors.grey),
      );
    }
    return AppNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      decodeWidth: 120,
      errorWidget: const Center(
        child: Icon(Icons.broken_image_outlined, color: AppColors.grey),
      ),
    );
  }
}

/// 26×26 white box wrapping a tappable icon (used for both "+" and "−").
/// Keeps a soft shadow so it stays visible against the light-green image bg.
class _IconBox extends StatelessWidget {
  const _IconBox({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 26.w,
        height: 26.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2.6.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 16.sp,
          color: enabled
              ? _kQtyAccent
              : AppColors.grey.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

/// 52×26 green (#84C318) pill showing the current cart quantity in white.
class _QtyDisplay extends StatelessWidget {
  const _QtyDisplay({required this.quantity});

  final int quantity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52.w,
      height: 26.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _kQtyBoxGreen,
        borderRadius: BorderRadius.circular(2.6.r),
      ),
      child: AppText(
        text: quantity.toString(),
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    );
  }
}

class _NameAndPrice extends StatelessWidget {
  const _NameAndPrice({required this.variant});

  final FrequentlyBoughtVariant variant;

  @override
  Widget build(BuildContext context) {
    final hasDiscount = variant.hasDiscount;
    final shownPrice = hasDiscount ? variant.discountedPrice : variant.price;
    final weightLabel = _formatWeightUnit(variant.weight, variant.stockUnit);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: variant.name,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
            maxLines: 2,
          ),
          if (weightLabel != null) ...[
            SizedBox(height: 4.h),
            AppText(
              text: weightLabel,
              fontSize: 11.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.grey,
            ),
          ],
          SizedBox(height: 4.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (shownPrice != null && shownPrice.isNotEmpty)
                AppText(
                  text: '₹${_formatPrice(shownPrice)}',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              if (hasDiscount && variant.price != null) ...[
                SizedBox(width: 6.w),
                AppText(
                  text: '₹${_formatPrice(variant.price!)}',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.grey,
                  decoration: TextDecoration.lineThrough,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(String raw) {
    final n = double.tryParse(raw);
    if (n == null) return raw;
    return n % 1 == 0 ? n.toInt().toString() : n.toStringAsFixed(2);
  }
}

/// Renders the weight + unit fields into a single display string.
/// Returns null when no weight value is available (caller should hide the row).
/// "100.00" + "g"     → "100 g"
/// "1.25"  + "kg"    → "1.25 kg"
/// "1"     + null    → "1"           (no unit fallback — show what backend gave)
/// null    + anything → null
String? _formatWeightUnit(String? weight, String? unit) {
  if (weight == null) return null;
  final trimmedWeight = weight.trim();
  if (trimmedWeight.isEmpty) return null;

  final trimmedUnit = unit?.trim();
  final hasUnit = trimmedUnit != null && trimmedUnit.isNotEmpty;

  // Normalise numeric weights — drop trailing ".00", keep meaningful decimals.
  final numeric = double.tryParse(trimmedWeight);
  final weightLabel = numeric != null
      ? (numeric % 1 == 0
            ? numeric.toInt().toString()
            : numeric
                  .toStringAsFixed(2)
                  .replaceFirst(RegExp(r'\.?0+$'), ''))
      : trimmedWeight;

  return hasUnit ? '$weightLabel $trimmedUnit' : weightLabel;
}
