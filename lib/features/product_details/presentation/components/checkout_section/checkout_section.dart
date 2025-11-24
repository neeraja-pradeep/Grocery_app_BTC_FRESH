import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/app_spacing.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/widgets/app_text.dart';

const String _rupeeSymbol = '₹';

/// Checkout section - Sticky bottom sheet with total price and cart action
///
/// This component displays:
/// - Total price calculation (unit price × quantity)
/// - View Cart button (currently placeholder)
/// - Green themed styling to match app branding
class CheckoutSection extends StatelessWidget {
  const CheckoutSection({
    super.key,
    required this.unitPrice,
    required this.quantity,
  });

  final double unitPrice;
  final int quantity;

  /// Calculate total price based on unit price and quantity
  double get _totalPrice => unitPrice * quantity;

  /// Format price for display (remove trailing zeros)
  String _formatPrice(double price) {
    return price.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.green10,
        boxShadow: [
          BoxShadow(
            color: AppColors.green50.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Total price column
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: 'Total price',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
              AppSpacing.h4,
              Text(
                quantity > 0
                    ? '$_rupeeSymbol${_formatPrice(_totalPrice)}'
                    : '$_rupeeSymbol 0',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          // View Cart button
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 65.w, vertical: 18.h),
              decoration: BoxDecoration(
                color: AppColors.green50,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green50.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AppText(
                text: 'View Cart',
                fontSize: 16.sp,
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
