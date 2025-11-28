import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/widgets/app_text.dart';
import 'package:grocery_app/features/cart/presentation/screen/coupons_screen.dart';

/// Checkout order summary component
/// Displays order breakdown, payment method, and place order button
class CheckoutOrderSummary extends StatelessWidget {
  const CheckoutOrderSummary({
    super.key,
    required this.itemTotal,
    required this.discount,
    required this.gst,
    required this.deliveryFee,
    required this.grandTotal,
    required this.onPlaceOrder,
    this.selectedPaymentMethod = 'UPI',
    this.deliveryAddressWidget,
  });

  final double itemTotal;
  final double discount;
  final double gst;
  final double deliveryFee;
  final double grandTotal;
  final VoidCallback onPlaceOrder;
  final String selectedPaymentMethod;
  final Widget? deliveryAddressWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Apply Coupon Section
          _buildApplyCouponSection(() {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CouponsScreen()),
            );
          }),

          Divider(height: 1, color: AppColors.grey.withValues(alpha: 0.2)),

          // Order Summary
          _buildOrderSummary(),

          // Delivery Address (between grand total and payment)
          if (deliveryAddressWidget != null) ...[
            Divider(height: 1, color: AppColors.grey.withValues(alpha: 0.2)),
            deliveryAddressWidget!,
          ],

          Divider(height: 1, color: AppColors.grey.withValues(alpha: 0.2)),

          // Payment Method and Place Order Button (side by side)
          _buildPaymentAndPlaceOrder(),
        ],
      ),
    );
  }

  Widget _buildApplyCouponSection(Function goto) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/svgs/order/coupon.svg',
            width: 16.w,
            height: 10.w,
            colorFilter: const ColorFilter.mode(
              AppColors.green100,
              BlendMode.srcIn,
            ),
          ),
          SizedBox(width: 8.w),
          AppText(
            text: 'APPLY COUPON',
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => goto(),
            child: Icon(
              Icons.arrow_forward_ios,
              color: AppColors.black,
              size: 14.sp,
              weight: 600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Column(
        children: [
          _buildSummaryRow('Item Total', itemTotal, isRegular: true),
          SizedBox(height: 8.h),
          _buildSummaryRow('Discount', discount, isDiscount: true),
          SizedBox(height: 8.h),
          _buildSummaryRow('GST', gst, isRegular: true),
          SizedBox(height: 8.h),
          _buildSummaryRow(
            'Delivery Fee',
            deliveryFee,
            isFree: deliveryFee == 0,
          ),
          SizedBox(height: 12.h),
          Divider(height: 1, color: AppColors.grey.withValues(alpha: 0.2)),
          SizedBox(height: 12.h),
          _buildSummaryRow('Grand Total', grandTotal, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double amount, {
    bool isRegular = false,
    bool isDiscount = false,
    bool isFree = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            text: label,
            fontSize: isTotal ? 16.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: isTotal
                ? AppColors.black
                : AppColors.black.withValues(alpha: 0.7),
          ),
          AppText(
            text: isFree ? 'Free' : amount.toStringAsFixed(0),
            fontSize: isTotal ? 16.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: isDiscount
                ? AppColors.green100
                : isTotal
                ? AppColors.red
                : AppColors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAndPlaceOrder() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          // Pay Using section (vertical layout)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppText(
                      text: 'Pay Using',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black.withValues(alpha: 0.7),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.grey,
                      size: 18.sp,
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                AppText(
                  text: selectedPaymentMethod,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ],
            ),
          ),

          SizedBox(width: 12.w),

          // Place Order Button
          GestureDetector(
            onTap: onPlaceOrder,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xFF8BC34A),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    text: '${grandTotal.toStringAsFixed(0)} |',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                  SizedBox(width: 8.w),
                  AppText(
                    text: 'Place Order',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
