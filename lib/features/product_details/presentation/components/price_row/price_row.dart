import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/widgets/app_text.dart';

const String _rupeeSymbol = '₹';

/// Price and Add to Cart Row Component
///
/// Displays unit price alongside add-to-cart controls (simple non-animated version)
/// - Left: Add button (quantity 0) or Quantity selector (quantity > 0)
/// - Right: Unit price in bold large text
///
/// Matches original UI exactly - simple buttons without animations
class PriceRow extends StatelessWidget {
  const PriceRow({
    super.key,
    required this.price,
    this.originalPrice,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    this.isEnabled = true,
  });

  final String price;
  final String? originalPrice; // Shown with strikethrough when discounted
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    // Check if we should show strikethrough original price
    final showOriginalPrice =
        originalPrice != null &&
        originalPrice!.isNotEmpty &&
        originalPrice != price;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Add button or Quantity selector
        SizedBox(
          width: 100.w,
          height: 44.h,
          child: quantity == 0
              ? _AddButton(onAdd: onAdd, isEnabled: isEnabled)
              : _QuantitySelector(
                  quantity: quantity,
                  onIncrement: onIncrement,
                  onDecrement: onDecrement,
                  isEnabled: isEnabled,
                ),
        ),
        // Price display with optional strikethrough original
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Current/discounted price
            Text(
              '$_rupeeSymbol$price',
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.black,
              ),
            ),
            // Original price with strikethrough (if discounted)
            if (showOriginalPrice) ...[
              SizedBox(width: 8.w),
              Text(
                '$_rupeeSymbol$originalPrice',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.grey,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Simple Add button - shown when quantity is 0
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onAdd, this.isEnabled = true});

  final VoidCallback onAdd;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onAdd : null,
      child: Opacity(
        opacity: isEnabled ? 1.0 : 0.5,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: isEnabled ? AppColors.green50 : AppColors.grey,
            borderRadius: BorderRadius.circular(10.r),
          ),
          alignment: Alignment.center,
          child: AppText(
            text: 'Add',
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16.sp,
          ),
        ),
      ),
    );
  }
}

/// Simple Quantity selector - shown when quantity > 0
/// Displays minus button, quantity number, and plus button
class _QuantitySelector extends StatelessWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    this.isEnabled = true,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Decrement button
        GestureDetector(
          onTap: onDecrement,
          child: const Icon(Icons.remove, color: AppColors.green100, size: 28),
        ),
        // Quantity display
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: AppColors.green50,
            border: Border.all(color: AppColors.green50, width: 1.5),
            borderRadius: BorderRadius.circular(8.r),
          ),
          alignment: Alignment.center,
          child: AppText(
            text: quantity.toString(),
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        // Increment button - disabled when out of stock
        GestureDetector(
          onTap: isEnabled ? onIncrement : null,
          child: Opacity(
            opacity: isEnabled ? 1.0 : 0.5,
            child: Icon(
              Icons.add,
              color: isEnabled ? AppColors.green100 : AppColors.grey,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}
