import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/app_text.dart';

/// Cart summary section
/// Displays total price and checkout button
class CartSummary extends StatelessWidget {
  const CartSummary({
    super.key,
    required this.totalWithoutTax,
    required this.onCheckout,
    required this.meetsMinimumOrder,
    this.minimumOrderMessage,
  });

  final double totalWithoutTax;
  final VoidCallback onCheckout;
  final bool meetsMinimumOrder;
  final String? minimumOrderMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.lightGreen),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Message about minimum order
          if (!meetsMinimumOrder && minimumOrderMessage != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              child: AppText(
                text: minimumOrderMessage!,
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.green100,
                textAlign: TextAlign.center,
              ),
            ),

          // Total and checkout button
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            child: Row(
              children: [
                // Total
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: 'Total (without tax)',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.black.withValues(alpha: 0.7),
                      ),
                      SizedBox(height: 4.h),
                      AppText(
                        text: '₹${totalWithoutTax.toStringAsFixed(2)}',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.red,
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 16.w),

                // Checkout button
                GestureDetector(
                  onTap: meetsMinimumOrder ? onCheckout : null,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: 14.h,
                    ),
                    decoration: BoxDecoration(
                      color: meetsMinimumOrder
                          ? const Color(0xFF8BC34A)
                          : AppColors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        AppText(
                          text: 'Checkout',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.arrow_forward,
                          color: AppColors.white,
                          size: 18.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
