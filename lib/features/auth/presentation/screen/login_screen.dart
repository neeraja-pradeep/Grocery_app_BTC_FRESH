// lib/features/auth/presentation/screen/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';

/// Login screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _showOtpField = false;
  bool _showPasswordField = false;
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 150.h),
                // App logo/title - centered
                Center(
                  child: Image.asset(
                    'assets/title.png',
                    height: 78.h,
                    width: 128.w,
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: 40.h),

                // Hi, Welcome! with hand wave
                Row(
                  children: [
                    Text(
                      'Hi, Welcome!',
                      style: TextStyle(
                        fontSize: 30.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green100,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Image.asset(
                      'assets/images/hand.png',
                      height: 30.w,
                      width: 30.w,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),

                SizedBox(height: 32.h),

                // Mobile Number label
                Text(
                  'Mobile Number',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.black,
                  ),
                ),

                SizedBox(height: 8.h),

                // Mobile Number input field
                Container(
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(color: AppColors.green, width: 2),
                  ),
                  child: TextField(
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Mobile Number',
                      hintStyle: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.grey,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 14.h,
                      ),
                    ),
                  ),
                ),

                // OTP Section - shown after Sign In is pressed
                if (_showOtpField) ...[
                  SizedBox(height: 16.h),

                  // OTP label
                  Text(
                    'OTP',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.black,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // OTP input field
                  Container(
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: AppColors.green, width: 2),
                    ),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'enter otp',
                        hintStyle: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                      ),
                    ),
                  ),
                ],

                // Password Section - shown after Sign in with password is pressed
                if (_showPasswordField) ...[
                  SizedBox(height: 16.h),

                  // Password label
                  Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.black,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Password input field
                  Container(
                    height: 50.h,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: AppColors.green, width: 2),
                    ),
                    child: TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'password',
                        hintStyle: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 14.h,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Remember me and Forgot password row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Remember me checkbox
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _rememberMe = !_rememberMe;
                          });
                        },
                        child: Row(
                          children: [
                            Container(
                              width: 20.w,
                              height: 20.w,
                              decoration: BoxDecoration(
                                color: _rememberMe
                                    ? AppColors.green
                                    : AppColors.white,
                                borderRadius: BorderRadius.circular(50.r),
                                border: Border.all(
                                  color: AppColors.green,
                                  width: 2,
                                ),
                              ),
                              child: _rememberMe
                                  ? Icon(
                                      Icons.check,
                                      size: 14.sp,
                                      color: AppColors.white,
                                    )
                                  : null,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'Remember me',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Forgot password
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRouter.forgotPassword,
                          );
                        },
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                SizedBox(height: 24.h),

                // Sign In button
                AppButton(
                  text: 'Sign In',
                  borderRadius: 10.r,
                  onPressed: () {
                    if (!_showOtpField && !_showPasswordField) {
                      // First click - show OTP field
                      setState(() {
                        _showOtpField = true;
                      });
                    } else {
                      // Handle sign in with OTP or password
                      // TODO: Handle verification
                    }
                  },
                ),

                // Sign in with password button - hidden after OTP or Password is shown
                if (!_showOtpField && !_showPasswordField) ...[
                  SizedBox(height: 16.h),

                  AppButton(
                    text: 'Sign in with password',
                    borderRadius: 10.r,
                    backgroundColor: AppColors.green.withValues(alpha: 0.2),
                    textColor: AppColors.green100,
                    onPressed: () {
                      setState(() {
                        _showPasswordField = true;
                      });
                    },
                  ),
                ],

                SizedBox(height: 32.h),

                // Don't have an account? Sign up
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, AppRouter.signUp);
                        },
                        child: Text(
                          'Sign up',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.green100,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // Skip
                Center(
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Skip to home
                    },
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green100,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.green100,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
