import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/colors.dart';

class AppInputField extends StatelessWidget {
  const AppInputField({
    super.key,
    required TextEditingController couponController,
    this.onChanged,
  }) : _couponController = couponController;

  final TextEditingController _couponController;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _couponController,
      onChanged: onChanged,
      style: TextStyle(fontFamily: 'Poppins', fontSize: 12.sp),
      decoration: InputDecoration(
        hintText: 'Enter coupon code',
        hintStyle: TextStyle(
          color: AppColors.lightGrey,
          fontSize: 12.sp,
          fontFamily: 'Poppins',
        ),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.lightGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.lightGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: const BorderSide(color: AppColors.green, width: 1.5),
        ),
      ),
    );
  }
}
