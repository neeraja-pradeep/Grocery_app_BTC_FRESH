import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/colors.dart';

class ProfileMenuItem extends StatelessWidget {
  const ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.showChevron = true,
    super.key,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 16.h,
        ),
        decoration: BoxDecoration(
          color: AppColors.green10,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24.sp,
              color: AppColors.green100,
            ),
            AppSpacing.w16,
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right,
                size: 24.sp,
                color: AppColors.grey,
              ),
          ],
        ),
      ),
    );
  }
}
