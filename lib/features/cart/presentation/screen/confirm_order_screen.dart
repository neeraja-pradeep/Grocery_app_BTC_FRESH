import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/button_styles.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/app_text.dart';

class ConfirmOrderScreen extends StatelessWidget {
  const ConfirmOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20.0.w),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 140.h),
                AppText(
                  text: 'Order Success!',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),

                SizedBox(height: 16.h),

                // Description
                AppText(
                  text:
                      'Your order is on the way. We\'ll keep you posted every step of the journey, so you\'ll know exactly when to get excited for your needs.',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.lightGrey,
                  textAlign: TextAlign.center,
                  maxLines: 5,
                ),
                SizedBox(height: 60.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/images/success.png',
                      width: 269.w,
                      height: 240.h,
                    ),
                    SizedBox(width: 40.w),
                  ],
                ),

                const Spacer(),

                // Back to Home Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ButtonStyles.greyButton,
                    child: AppText(
                      text: 'Back',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.black,
                    ),
                  ),
                ),

                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
