import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/widgets/app_text.dart';
import '../../../../cart/application/providers/checkout_line_provider.dart';
import '../../../../cart/domain/entities/checkout_line.dart';

/// Cart Items Section Component
///
/// Displays all items currently in the cart with quantity controls
/// Shows below the review section on product details page
/// Allows users to adjust quantities while browsing products
class CartItemsSection extends ConsumerWidget {
  const CartItemsSection({
    super.key,
    required this.onIncrement,
    required this.onDecrement,
  });

  final void Function(int cartLineId) onIncrement;
  final void Function(int cartLineId) onDecrement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkoutState = ref.watch(checkoutLineControllerProvider);
    final items = checkoutState.items;

    // Don't show section if cart is empty
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cart items list (no header)
          ...items.map(
            (item) => _CartItemRow(
              item: item,
              onIncrement: () => onIncrement(item.id),
              onDecrement: () => onDecrement(item.id),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual cart item row with product info and quantity controls
class _CartItemRow extends StatelessWidget {
  const _CartItemRow({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
  });

  final CheckoutLine item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    final variant = item.productVariantDetails;
    final imageUrl = variant.media.isNotEmpty ? variant.media.first : null;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          // Product image
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6.r),
              color: AppColors.grey.withValues(alpha: 0.1),
            ),
            child: imageUrl != null && imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.grey,
                          size: 24.sp,
                        );
                      },
                    ),
                  )
                : Icon(
                    Icons.shopping_basket_outlined,
                    color: AppColors.grey,
                    size: 24.sp,
                  ),
          ),
          SizedBox(width: 10.w),
          // Product info
          Expanded(
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
                AppSpacing.h4,
                AppText(
                  text: '₹${variant.effectivePrice.toStringAsFixed(2)}',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green,
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          // Quantity controls
          _QuantityControls(
            quantity: item.quantity,
            onIncrement: onIncrement,
            onDecrement: onDecrement,
          ),
        ],
      ),
    );
  }
}

/// Quantity control buttons (+ and -)
class _QuantityControls extends StatelessWidget {
  const _QuantityControls({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Decrement button
        _QuantityButton(icon: Icons.remove, onTap: onDecrement),
        SizedBox(width: 6.w),
        // Quantity display
        Container(
          width: 28.w,
          height: 24.h,
          decoration: BoxDecoration(
            color: AppColors.green50,
            borderRadius: BorderRadius.circular(4.r),
          ),
          alignment: Alignment.center,
          child: AppText(
            text: quantity.toString(),
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        SizedBox(width: 6.w),
        // Increment button
        _QuantityButton(icon: Icons.add, onTap: onIncrement),
      ],
    );
  }
}

/// Individual quantity control button
class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28.w,
        height: 24.h,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(
            color: AppColors.grey.withValues(alpha: 0.3),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(4.r),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 14.sp, color: AppColors.grey),
      ),
    );
  }
}
