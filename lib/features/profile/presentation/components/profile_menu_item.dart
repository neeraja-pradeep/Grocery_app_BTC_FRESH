import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/colors.dart';

class ProfileMenuItem extends StatelessWidget {
  const ProfileMenuItem({
    required this.title,
    required this.onTap,
    this.icon,
    this.imagePath,
    this.showChevron = true,
    this.titleFontSize,
    this.titleFontWeight,
    super.key,
  });

  final IconData? icon;
  final String? imagePath;
  final String title;
  final VoidCallback onTap;
  final bool showChevron;
  final double? titleFontSize;
  final FontWeight? titleFontWeight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: AppColors.field,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            if (imagePath != null)
              Image.asset(imagePath!, width: 24.sp, height: 24.sp)
            else if (icon != null)
              Icon(icon, size: 24.sp, color: AppColors.green100),
            AppSpacing.w16,
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: titleFontSize ?? 14.sp,
                  fontWeight: titleFontWeight ?? FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right, size: 24.sp, color: AppColors.grey),
          ],
        ),
      ),
    );
  }
}
