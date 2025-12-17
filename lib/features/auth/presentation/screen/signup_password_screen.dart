// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/utils/app_button.dart';
import '../../../../core/utils/app_text_field.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../application/providers/auth_provider.dart';
import '../../application/states/auth_state.dart';

class SignupPasswordScreen extends ConsumerStatefulWidget {
  final String username;
  final String email;
  final String first;
  final String last;
  final String number;
  const SignupPasswordScreen({
    super.key,
    required this.username,
    required this.email,
    required this.first,
    required this.last,
    required this.number,
  });

  @override
  ConsumerState<SignupPasswordScreen> createState() =>
      _SignupPasswordScreenState();
}

class _SignupPasswordScreenState extends ConsumerState<SignupPasswordScreen> {
  late TextEditingController nameController;
  late TextEditingController numberController;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: '${widget.first} ${widget.last}',
    );
    numberController = TextEditingController(text: widget.number);
  }

  final passwordController = TextEditingController();

  final confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // 🔥 Listen to state changes
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next is Authenticated) {
        if (next.isNewUser) {
          // new users → go to address screen
          goToAddress(context, next.user);
        } else {
          goToHome(context);
        }
      }

      if (next is AuthError) {
        _showError(next.failure.message);
      }
    });
    return Scaffold(
      body: Center(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(18.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                Center(child: Image.asset('assets/title.png', width: 120.w)),
                SizedBox(height: 10.h),

                Text(
                  'Sign up',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28.sp,
                    color: AppColors.titleColor,
                  ),
                ),

                SizedBox(height: 15.h),

                const Text(
                  'Name',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 5.h),
                AppTextField(
                  controller: nameController,
                  hintText: 'Name',
                  icon: null,
                  isObscure: false,
                ),

                SizedBox(height: 15.h),

                const Text(
                  'Mobile Number',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 5.h),
                AppTextField(
                  controller: numberController,
                  hintText: 'Mobile Number',
                  icon: null,
                  isObscure: false,
                ),

                SizedBox(height: 15.h),

                const Text(
                  'Create a password',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 5.h),
                AppTextField(
                  controller: passwordController,
                  hintText: 'Must be 8 Characters',
                  icon: Icons.remove_red_eye,
                  isObscure: true,
                ),

                SizedBox(height: 15.h),

                // Last Name
                const Text(
                  'Confirm Password',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 5.h),
                AppTextField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  icon: Icons.remove_red_eye,
                  isObscure: true,
                ),

                SizedBox(height: 25.h),

                // SIGN UP BUTTON
                GestureDetector(
                  onTap: () => _handleSignup(authState),
                  child: AppButton(
                    text: authState is AuthLoading
                        ? 'Creating Account...'
                        : 'Sign Up',
                    loading: authState is AuthLoading,
                  ),
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

  void _handleSignup(AuthState state) {
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    // Check if fields are empty
    if ([password].any((e) => e.isEmpty)) {
      _showError('All fields are required');
      return;
    }

    // Check password length
    if (password.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }

    // Check if passwords match
    if (password != confirm) {
      _showError('Passwords do not match');
      return;
    }

    ref
        .read(authProvider.notifier)
        .signup(
          username: widget.username,
          email: widget.email,
          firstName: widget.first,
          lastName: widget.last,
          phoneNumber: '+91${widget.number}',
          password: password,
          confirmPassword: confirm,
        );
  }

  void _showError(String msg) {
    AppSnackbar.error(context, msg);
  }
}
