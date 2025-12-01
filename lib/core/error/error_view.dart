import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../app/theme/colors.dart';
import '../widgets/app_text.dart';

/// Error view page displayed when something goes wrong
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, this.onGoHome});

  final VoidCallback? onGoHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/error_background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error box image
              Image.asset(
                'assets/images/error_box.png',
                width: 222.h,
                height: 222.h,
              ),
              SizedBox(height: 24.h),
              // Title
              AppText(
                text: 'Well, this is awkward...',
                fontSize: 26.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.green100,
              ),
              SizedBox(height: 12.h),
              // Subtitle
              AppText(
                text: "It's not you, it's us. Hang tight, we're fixing it!",
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.green100,
              ),
              SizedBox(height: 32.h),
              // Go To Home button
              _buildGoHomeButton(context),
            ],
          ),
        ),
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
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Center(
            child: AppText(
              text: 'Go To Home',
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
