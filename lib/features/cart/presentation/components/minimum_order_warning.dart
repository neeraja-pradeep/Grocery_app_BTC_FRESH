import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/widgets/app_text.dart';

/// Minimum order warning banner
/// Shows when cart total is below minimum order value
class MinimumOrderWarning extends StatelessWidget {
  const MinimumOrderWarning({super.key, required this.minimumValue});

  final double minimumValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: const Color(0xFFD32F2F),
            size: 18.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: AppText(
              text:
                  'You haven\'t reached the minimum order value of $minimumValue',
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFD32F2F),
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
