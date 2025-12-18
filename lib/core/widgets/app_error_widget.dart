import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../app/theme/colors.dart';
import '../../features/bottomnavbar/bottom_navbar.dart';
import 'app_text.dart';

/// Full screen error widget with box illustration
/// Use this when a screen fails to load or encounters an error
class AppErrorScreen extends StatelessWidget {
  const AppErrorScreen({
    super.key,
    this.title = 'Well, this is awkward...',
    this.subtitle = "It's not you, it's us. Hang tight, we're fixing it!",
    this.buttonText = 'Go To Home',
    this.onButtonPressed,
    this.showButton = true,
  });

  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback? onButtonPressed;
  final bool showButton;

  /// Navigate to home tab using bottom navigation
  static void goToHome(BuildContext context) {
    BottomNavigation.globalKey.currentState?.navigateToTab(0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        image: DecorationImage(
          image: AssetImage('assets/images/error_background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error illustration - use asset image
              Image.asset(
                'assets/images/error_box.png',
                width: 150.w,
                height: 150.h,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to drawn illustration if asset not found
                  return _buildErrorIllustration();
                },
              ),

              SizedBox(height: 32.h),

              // Title
              AppText(
                text: title,
                fontSize: 22.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.green100,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 8.h),

              // Subtitle
              AppText(
                text: subtitle,
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.green100,
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 32.h),

              // Go To Home button
              if (showButton)
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: onButtonPressed ?? () => goToHome(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green50,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: AppText(
                      text: buttonText,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorIllustration() {
    return SizedBox(
      width: 150.w,
      height: 150.h,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Sad box
          Container(
            width: 120.w,
            height: 100.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFE8A54B), // Light brown/orange
                  Color(0xFFD4863D), // Darker brown/orange
                ],
              ),
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Box tape/stripe
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 20.h,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4863D),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8.r),
                      ),
                    ),
                  ),
                ),
                // Sad face
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 10.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Eyes
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildEye(),
                            SizedBox(width: 20.w),
                            _buildEye(),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        // Sad mouth
                        Container(
                          width: 30.w,
                          height: 15.h,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: const Color(0xFF8B5A2B),
                                width: 3.w,
                              ),
                            ),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(15.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Download/arrow icon on top right
          Positioned(
            top: 0,
            right: 10.w,
            child: Container(
              width: 50.w,
              height: 50.h,
              decoration: BoxDecoration(
                color: AppColors.green50,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green50.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_downward_rounded,
                color: Colors.white,
                size: 28.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEye() {
    return Container(
      width: 8.w,
      height: 8.h,
      decoration: const BoxDecoration(
        color: Color(0xFF8B5A2B),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Error bottom sheet for cart/checkout errors
/// Shows a smaller error message at the bottom of the screen
class AppErrorBottomSheet extends StatelessWidget {
  const AppErrorBottomSheet({
    super.key,
    this.title = 'Oops!',
    this.subtitle = 'Looks like something went wrong. We are fixing it.',
    this.buttonText = 'Go to Home',
    this.onButtonPressed,
  });

  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback? onButtonPressed;

  /// Show the error bottom sheet
  static Future<void> show(
    BuildContext context, {
    String title = 'Oops!',
    String subtitle = 'Looks like something went wrong. We are fixing it.',
    String buttonText = 'Go to Home',
    VoidCallback? onButtonPressed,
  }) {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => AppErrorBottomSheet(
        title: title,
        subtitle: subtitle,
        buttonText: buttonText,
        onButtonPressed: onButtonPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          AppText(
            text: title,
            fontSize: 20.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 8.h),

          // Subtitle
          AppText(
            text: subtitle,
            fontSize: 14.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.grey,
            textAlign: TextAlign.center,
          ),

          SizedBox(height: 24.h),

          // Go to Home button
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed:
                  onButtonPressed ??
                  () {
                    Navigator.of(context).pop(); // Close bottom sheet
                    AppErrorScreen.goToHome(context);
                  },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green50,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: AppText(
                text: buttonText,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 8.h),
        ],
      ),
    );
  }
}

/// Helper class for showing error widgets
class AppError {
  /// Show full screen error (use as a replacement widget)
  static Widget screen({
    String title = 'Well, this is awkward...',
    String subtitle = "It's not you, it's us. Hang tight, we're fixing it!",
    String buttonText = 'Go To Home',
    VoidCallback? onButtonPressed,
    bool showButton = true,
  }) {
    return AppErrorScreen(
      title: title,
      subtitle: subtitle,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
      showButton: showButton,
    );
  }

  /// Show error bottom sheet (for cart/checkout errors)
  static Future<void> showBottomSheet(
    BuildContext context, {
    String title = 'Oops!',
    String subtitle = 'Looks like something went wrong. We are fixing it.',
    String buttonText = 'Go to Home',
    VoidCallback? onButtonPressed,
  }) {
    return AppErrorBottomSheet.show(
      context,
      title: title,
      subtitle: subtitle,
      buttonText: buttonText,
      onButtonPressed: onButtonPressed,
    );
  }
}
