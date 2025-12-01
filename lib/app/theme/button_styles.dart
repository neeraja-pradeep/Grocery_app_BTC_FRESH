import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'colors.dart';

class ButtonStyles {
  static final ButtonStyle greenButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.green,
    elevation: 0,
    padding: EdgeInsets.symmetric(vertical: 16.h),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
  );

  static final ButtonStyle lightgreenButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.lightGreen,
    elevation: 0,
    padding: EdgeInsets.symmetric(vertical: 16.h),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
  );

  static final ButtonStyle greyButton = ElevatedButton.styleFrom(
    backgroundColor: AppColors.grey.withValues(alpha: 0.3),
    elevation: 0,
    padding: EdgeInsets.symmetric(vertical: 16.h),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
  );
}
