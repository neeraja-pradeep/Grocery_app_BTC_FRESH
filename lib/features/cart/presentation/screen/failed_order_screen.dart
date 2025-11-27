import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/button_styles.dart';
import 'package:grocery_app/app/theme/colors.dart';

class FailedOrderScreen extends StatelessWidget {
  const FailedOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
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

              Text(
                'Oops! Order Failed',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),

              SizedBox(height: 12.h),

              Text(
                'Something went terribly wrong.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.lightGrey,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Poppins',
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ButtonStyles.greenButton,
                  child: Text(
                    'Go to cart',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),

              SizedBox(height: 16.h),

              // Back to Home Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate to home
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ButtonStyles.greyButton,
                  child: Text(
                    'Back to Home',
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
