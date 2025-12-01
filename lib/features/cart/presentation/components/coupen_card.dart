import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/app_text.dart';

class CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback onApply;

  const CouponCard({super.key, required this.coupon, required this.onApply});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.lightGrey),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Green Indicator
              Container(
                width: 18.w,
                height: 18.h,
                decoration: const BoxDecoration(
                  color: AppColors.couponGreen,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12.w),

              // Coupon Code
              AppText(
                text: coupon.code,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.black,
              ),

              const Spacer(),

              // Apply Button
              GestureDetector(
                onTap: onApply,
                child: AppText(
                  text: 'APPLY',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.couponGreen,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 0.3),

          // Title
          AppText(
            text: coupon.title,
            fontSize: 10.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.lightGrey,
          ),
          SizedBox(height: 8.h),

          // Description
          AppText(
            text: coupon.description,
            fontSize: 10.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.lightGrey,
          ),
        ],
      ),
    );
  }
}

class CouponModel {
  final String code;
  final String title;
  final String description;

  CouponModel({
    required this.code,
    required this.title,
    required this.description,
  });
}
