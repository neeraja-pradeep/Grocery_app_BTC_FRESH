import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/app_button.dart';

/// Sign Up Screen - New user registration
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() {
    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validate fields
    if (name.isEmpty) {
      _showError('Please enter your name');
      return;
    }

    if (mobile.isEmpty || mobile.length < 10) {
      _showError('Please enter a valid mobile number');
      return;
    }

    if (password.isEmpty || password.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }

    if (password != confirmPassword) {
      _showError('Passwords do not match');
      return;
    }

    // TODO: Call API to register user
    // On success, navigate to address screen
    Navigator.pushNamed(context, AppRouter.address);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

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
                SizedBox(height: 60.h),

                // App logo - centered
                Center(
                  child: Image.asset(
                    'assets/title.png',
                    height: 78.h,
                    width: 128.w,
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: 32.h),

                // Sign up heading
                Text(
                  'Sign up',
                  style: TextStyle(
                    fontSize: 30.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green100,
                  ),
                ),

                SizedBox(height: 24.h),

                // Name label
                Text(
                  'Name',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.black,
                  ),
                ),

                SizedBox(height: 8.h),

                // Name input field
                _buildTextField(
                  controller: _nameController,
                  hintText: 'Name',
                  keyboardType: TextInputType.name,
                ),

                SizedBox(height: 16.h),

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
                _buildTextField(
                  controller: _mobileController,
                  hintText: 'Mobile Number',
                  keyboardType: TextInputType.phone,
                ),

                SizedBox(height: 16.h),

                // Create a password label
                Text(
                  'Create a password',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.black,
                  ),
                ),

                SizedBox(height: 8.h),

                // Password input field
                _buildTextField(
                  controller: _passwordController,
                  hintText: 'must be 8 characters',
                  obscureText: _obscurePassword,
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    child: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.grey,
                      size: 22.sp,
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Confirm password label
                Text(
                  'Confirm password',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.black,
                  ),
                ),

                SizedBox(height: 8.h),

                // Confirm password input field
                _buildTextField(
                  controller: _confirmPasswordController,
                  hintText: 'repeat password',
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: GestureDetector(
                    onTap: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    child: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.grey,
                      size: 22.sp,
                    ),
                  ),
                ),

                SizedBox(height: 32.h),

                // Sign Up button
                AppButton(
                  text: 'Sign Up',
                  borderRadius: 10.r,
                  onPressed: _handleSignUp,
                ),

                SizedBox(height: 24.h),

                // Already have an account? Log in
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w400,
                          color: AppColors.black,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(
                            context,
                            AppRouter.login,
                          );
                        },
                        child: Text(
                          'Log in',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
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
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}
