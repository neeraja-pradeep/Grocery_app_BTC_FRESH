import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/colors.dart';

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
              Text(
                coupon.code,
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),

              const Spacer(),

              // Apply Button
              GestureDetector(
                onTap: onApply,
                child: Text(
                  'APPLY',
                  style: TextStyle(
                    color: AppColors.couponGreen,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.grey, thickness: 0.3),

          // Title
          Text(
            coupon.title,
            style: TextStyle(
              color: AppColors.lightGrey,
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          SizedBox(height: 8.h),

          // Description
          Text(
            coupon.description,
            style: TextStyle(
              color: AppColors.lightGrey,
              fontSize: 10.sp,
              fontFamily: 'Poppins',
            ),
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
