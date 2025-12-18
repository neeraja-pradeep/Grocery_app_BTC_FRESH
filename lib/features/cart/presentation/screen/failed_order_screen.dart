import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/button_styles.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/app_text.dart';

class FailedOrderScreen extends StatelessWidget {
  const FailedOrderScreen({super.key});

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
                  text: 'Oops! Order Failed',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),

                SizedBox(height: 12.h),

                AppText(
                  text: 'Something went terribly wrong.',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.lightGrey,
                  textAlign: TextAlign.center,
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.go('/cart');
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
