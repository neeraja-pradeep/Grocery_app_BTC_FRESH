import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/button_styles.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../bottomnavbar/bottom_navbar.dart';

class FailedOrderScreen extends StatelessWidget {
  final String? errorMessage;
  final bool isReservationExpired;

  const FailedOrderScreen({
    super.key,
    this.errorMessage,
    this.isReservationExpired = false,
  });

  String get _title {
    if (isReservationExpired) {
      return 'Session Expired';
    }
    return 'Oops! Order Failed';
  }

  String get _subtitle {
    if (isReservationExpired) {
      return 'Your cart reservation expired. If payment was deducted, it will be refunded automatically within 5-7 business days.';
    }
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return errorMessage!;
    }
    return 'Something went terribly wrong.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.0.w),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 120.h),

                Center(
                  child: Image.asset(
                    'assets/images/bag.png',
                    width: 222.w,
                    height: 221.h,
                  ),
                ),

                SizedBox(height: 40.h),

                AppText(
                  text: _title,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),

                SizedBox(height: 12.h),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: AppText(
                    text: _subtitle,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.lightGrey,
                    textAlign: TextAlign.center,
                  ),
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate back to home/main screen first
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      // Then navigate to cart tab via bottom navigation
                      BottomNavigation.globalKey.currentState?.navigateToTab(3);
                    },
                    style: ButtonStyles.greenButton,
                    child: AppText(
                      text: 'Go to cart',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.white,
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Back to Home Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/home');
                    },
                    style: ButtonStyles.greyButton,
                    child: AppText(
                      text: 'Back to Home',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                ),

                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
