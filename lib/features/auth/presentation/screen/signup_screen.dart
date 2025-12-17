import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/utils/app_button.dart';
import '../../../../core/utils/app_text_field.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../application/providers/auth_provider.dart';

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
      body: Padding(
        padding: EdgeInsets.all(10.0.w),
        child: Center(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Image.asset('assets/title.png', width: 110.w)),
                  SizedBox(height: 10.h),

                  Text(
                    'Sign up',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28.sp,
                      color: AppColors.titleColor,
                    ),
                  ),

                  SizedBox(height: 10.h),

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
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'\s')),
                    ],
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

                  SizedBox(height: 20.h),

                  // Skip Button
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        // Activate guest mode
                        ref.read(authProvider.notifier).continueAsGuest();
                        goToHome(context);
                      },
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          decoration: TextDecoration.underline,
                          color: AppColors.titleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
  );

  void _handleSignup() {
    final username = useridController.text.trim();
    final email = emailController.text.trim();
    final number = phoneNumberController.text.trim();
    final first = firstNameController.text.trim();
    final last = lastNameController.text.trim();

    // Check if fields are empty
    if ([username, email, number, first, last].any((e) => e.isEmpty)) {
      _showError('All fields are required');
      return;
    }

    // Validate first name - only letters and spaces allowed
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(first)) {
      _showError('First name must contain only letters');
      return;
    }

    // Validate last name - only letters and spaces allowed
    if (!nameRegex.hasMatch(last)) {
      _showError('Last name must contain only letters');
      return;
    }

    // Validate email format
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address');
      return;
    }

    // Validate phone number length
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
    AppSnackbar.error(context, msg);
  }
}
