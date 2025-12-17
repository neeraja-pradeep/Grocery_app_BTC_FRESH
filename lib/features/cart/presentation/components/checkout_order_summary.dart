import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/app_text.dart';
import '../../application/providers/applied_coupon_provider.dart';
import '../../application/providers/checkout_line_provider.dart';
import '../../application/providers/coupon_providers.dart';
import '../../domain/entities/coupon.dart';
import '../screen/coupons_screen.dart';

/// Checkout order summary component
/// Displays order breakdown, payment method, and place order button
class CheckoutOrderSummary extends ConsumerWidget {
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
    this.appliedCoupon,
  });

  final double itemTotal;
  final double discount;
  final double gst;
  final double deliveryFee;
  final double grandTotal;
  final VoidCallback onPlaceOrder;
  final String selectedPaymentMethod;
  final Widget? deliveryAddressWidget;
  final Coupon? appliedCoupon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          _buildApplyCouponSection(context, ref),

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

  Widget _buildApplyCouponSection(BuildContext context, WidgetRef ref) {
    final hasCoupon = appliedCoupon != null;

    return InkWell(
      onTap: hasCoupon ? null : () => _navigateToCoupons(context, ref),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/svgs/order/coupon.svg',
              width: 16.w,
              height: 10.w,
              colorFilter: ColorFilter.mode(
                hasCoupon ? AppColors.couponGreen : AppColors.green100,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (hasCoupon) ...[
                    // Show applied coupon
                    Row(
                      children: [
                        AppText(
                          text: appliedCoupon!.name,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.couponGreen,
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.couponGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: AppText(
                            text: 'APPLIED',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.couponGreen,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    AppText(
                      text:
                          'You saved ₹${discount.toStringAsFixed(0)} on this order!',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.couponGreen,
                    ),
                  ] else ...[
                    AppText(
                      text: 'APPLY COUPON',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.black,
                    ),
                  ],
                ],
              ),
            ),
            if (hasCoupon)
              GestureDetector(
                onTap: () {
                  ref.read(appliedCouponProvider.notifier).removeCoupon();
                },
                child: Icon(Icons.close, color: AppColors.grey, size: 18.sp),
              )
            else
              Icon(
                Icons.arrow_forward_ios,
                color: AppColors.black,
                size: 14.sp,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToCoupons(BuildContext context, WidgetRef ref) async {
    // Navigate to coupons screen and wait for result
    final selectedCouponCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const CouponsScreen()),
    );

    // If a coupon was selected, find and apply it
    if (selectedCouponCode != null) {
      final couponState = ref.read(couponControllerProvider);
      final selectedCoupon = couponState.coupons.firstWhere(
        (c) => c.name == selectedCouponCode,
        orElse: () => throw Exception('Coupon not found'),
      );

      // Get current item total
      final checkoutState = ref.read(checkoutLineControllerProvider);
      final currentItemTotal = checkoutState.totalAmount;

      // Apply the coupon
      ref
          .read(appliedCouponProvider.notifier)
          .applyCoupon(selectedCoupon, currentItemTotal);
    }
  }

  Widget _buildOrderSummary() {
    final hasCoupon = appliedCoupon != null;
    final discountLabel = hasCoupon
        ? 'Discount (${appliedCoupon!.discountPercentage}%)'
        : 'Discount';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Column(
        children: [
          _buildSummaryRow('Item Total', itemTotal, isRegular: true),
          SizedBox(height: 8.h),
          _buildSummaryRow(
            discountLabel,
            discount,
            isDiscount: true,
            showMinus: discount > 0,
          ),
          SizedBox(height: 8.h),
          _buildSummaryRow('GST (18%)', gst, isRegular: true),
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
    bool showMinus = false,
  }) {
    String amountText;
    if (isFree) {
      amountText = 'Free';
    } else if (isDiscount && showMinus) {
      amountText = '-₹${amount.toStringAsFixed(0)}';
    } else {
      amountText = '₹${amount.toStringAsFixed(0)}';
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
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
            text: amountText,
            fontSize: isTotal ? 16.sp : 14.sp,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            color: isDiscount
                ? AppColors.couponGreen
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
                    text: '₹${grandTotal.toStringAsFixed(0)} |',
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
