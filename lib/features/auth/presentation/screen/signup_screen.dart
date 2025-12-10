import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/utils/app_button.dart';
import '../../../../core/utils/app_text_field.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final useridController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40.h),
                Center(child: Image.asset('assets/title.png', width: 130.w)),
                SizedBox(height: 10.h),

                Text(
                  'Sign up',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 35.sp,
                    color: AppColors.titleColor,
                  ),
                ),

                SizedBox(height: 15.h),

                // USER ID
                _label('User ID'),
                SizedBox(height: 5.h),
                AppTextField(
                  controller: useridController,
                  hintText: 'User ID',
                  icon: null,
                  isObscure: false,
                ),

                SizedBox(height: 15.h),

                // EMAIL
                _label('Email'),
                SizedBox(height: 5.h),
                AppTextField(
                  controller: emailController,
                  hintText: 'Email',
                  icon: null,
                  isObscure: false,
                ),

                SizedBox(height: 15.h),

                // PHONE NUMBER
                _label('Phone Number'),
                SizedBox(height: 5.h),
                AppTextField(
                  controller: phoneNumberController,
                  icon: null,
                  isObscure: false,
                  hintText: 'Phone Number',
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),

                SizedBox(height: 15.h),

                // First Name
                _label('First Name'),
                SizedBox(height: 5.h),
                AppTextField(
                  controller: firstNameController,
                  hintText: 'First Name',
                  icon: null,
                  isObscure: false,
                ),

                SizedBox(height: 15.h),

                // Last Name
                _label('Last Name'),
                SizedBox(height: 5.h),
                AppTextField(
                  controller: lastNameController,
                  hintText: 'Last Name',
                  icon: null,
                  isObscure: false,
                ),

                SizedBox(height: 20.h),
                // SIGN UP BUTTON
                GestureDetector(
                  onTap: () => {_handleSignup()},
                  child: const AppButton(text: 'Sign Up'),
                ),

                SizedBox(height: 20.h),

                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    SizedBox(width: 5.w),
                    GestureDetector(
                      onTap: () => goToLogin(context),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: AppColors.titleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w500));

  void _handleSignup() {
    final username = useridController.text.trim();
    final email = emailController.text.trim();
    final number = phoneNumberController.text.trim();
    final first = firstNameController.text.trim();
    final last = lastNameController.text.trim();

    if ([username, email, number, first, last].any((e) => e.isEmpty)) {
      _showError('All fields are required');
      return;
    }

    if (number.length != 10) {
      _showError('Phone number must be exactly 10 digits');
      return;
    }

    goToSignWithPass(
      context,
      username: username,
      email: email,
      first: first,
      last: last,
      number: number,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
