import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.fullName,
    required this.mobileNumber,
    required this.onEditTap,
    this.profileImageUrl,
    super.key,
  });

  final String fullName;
  final String mobileNumber;
  final String? profileImageUrl;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32.r,
            backgroundColor: AppColors.grey.withValues(alpha: 0.2),
            // Disk-cached and decoded at avatar size (64 logical px at 3x)
            // rather than at the source resolution.
            backgroundImage: profileImageUrl != null
                ? ResizeImage(
                    CachedNetworkImageProvider(profileImageUrl!),
                    width: 192,
                  )
                : null,
            child: profileImageUrl == null
                ? Icon(Icons.person, size: 32.sp, color: AppColors.grey)
                : null,
          ),
          AppSpacing.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.black,
                  ),
                ),
                AppSpacing.h4,
                Text(
                  mobileNumber,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: onEditTap,
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.all(8.w),
              child: Image.asset(
                'assets/svgs/profile/edit.png',
                height: 20.h,
                width: 20.w,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
