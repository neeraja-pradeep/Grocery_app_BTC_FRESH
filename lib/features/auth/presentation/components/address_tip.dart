import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';

class AddressTip extends StatelessWidget {
  const AddressTip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      height: 60.h,
      decoration: BoxDecoration(
        color: AppColors.lightGreen,
        border: Border.all(color: AppColors.borderColor),
        borderRadius: BorderRadius.circular(10),
      ),

      child: Center(
        child: Text(
          'A Detailed address will help our delivery partner reach your doorstep easily',

          style: TextStyle(
            fontSize: 12.sp,
            color: AppColors.titleColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
