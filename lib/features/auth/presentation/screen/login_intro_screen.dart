// lib/features/auth/presentation/screen/login_intro_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';

/// Login intro screen - First screen shown to users
class LoginIntroScreen extends StatelessWidget {
  const LoginIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background_graphics.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  // Spacer to push content to center
                  SizedBox(height: 24.h),
                  const Spacer(),

                  // Delivery illustration
                  Image.asset(
                    'assets/images/login.png',
                    height: 131.h,
                    width: 196.h,
                    fit: BoxFit.contain,
                  ),

                  SizedBox(height: 24.h),

                  // App logo/title
                  Image.asset(
                    'assets/title.png',
                    height: 40.h,
                    fit: BoxFit.contain,
                  ),

                  // Main heading
                  Text(
                    'Get your groceries\ndelivered to your home',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green100,
                      height: 1.2,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Subtitle
                  Text(
                    'The best delivery app in town for\ndelivering your daily fresh groceries',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey,
                      height: 1.4,
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Next button
                  AppButton(
                    borderRadius: 10.r,
                    text: 'Next',
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.login);
                    },
                  ),

                  // Spacer to push content up from bottom
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
