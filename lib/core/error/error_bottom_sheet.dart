import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app/theme/colors.dart';
import '../widgets/app_text.dart';

/// Error bottom sheet component displayed when something goes wrong
class ErrorBottomSheet extends StatelessWidget {
  const ErrorBottomSheet({super.key, this.onGoHome});

  final VoidCallback? onGoHome;

  /// Shows the error bottom sheet
  static Future<void> show(BuildContext context, {VoidCallback? onGoHome}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          ErrorBottomSheet(onGoHome: onGoHome ?? () => Navigator.pop(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 226.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 24.h),
          // Title
          AppText(
            text: 'Oops!',
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
          SizedBox(height: 16.h),
          // Subtitle
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: AppText(
              text: 'Looks like something went wrong. We are fixing it.',
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
          SizedBox(height: 24.h),
          // Go To Home button
          _buildGoHomeButton(context),
          SizedBox(height: 40.h),
        ],
      ),
    );
  }

  Widget _buildGoHomeButton(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: GestureDetector(
        onTap: onGoHome,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Center(
            child: AppText(
              text: 'Go to Home',
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ),
      ),
    );
  }
}
