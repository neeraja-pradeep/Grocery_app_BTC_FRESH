import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/widgets/app_text.dart';

const String _rupeeSymbol = '₹';

/// Checkout section - Sticky bottom sheet with total price and cart action
///
/// This component displays:
/// - Total price calculation (unit price × quantity)
/// - View Cart button (when quantity > 0 and total <= 150)
/// - Checkout button (when total > 150)
/// - Disabled state (when quantity = 0)
/// - Green themed styling to match app branding
class CheckoutSection extends StatelessWidget {
  const CheckoutSection({
    super.key,
    required this.unitPrice,
    required this.quantity,
    this.onViewCart,
    this.onCheckout,
    this.onAddToCart,
  });

  final double unitPrice;
  final int quantity;
  final VoidCallback? onViewCart;
  final VoidCallback? onCheckout;
  final VoidCallback? onAddToCart;

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
        color: const Color(0xFFC9F4AA),
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

          // Action button based on state
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    // State 1: No quantity selected - disabled button
    if (quantity <= 0) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 18.h),
        decoration: BoxDecoration(
          color: AppColors.grey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: AppText(
          text: 'View Cart',
          fontSize: 16.sp,
          color: AppColors.grey,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    // State 2: Quantity > 0 - show View Cart button
    return GestureDetector(
      onTap: onViewCart ?? onAddToCart,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 50.w, vertical: 18.h),
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
    );
  }
}
