// lib/features/auth/presentation/screen/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/app_button.dart';
import '../../../../core/utils/app_text_field.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../application/providers/auth_provider.dart';
import '../../application/states/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String? redirectTo;

  const LoginScreen({super.key, this.redirectTo});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen<AuthState>(authProvider, (prev, next) {
      _handleAuthState(next);
    });

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(8.w),
        child: Center(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40.h),
                  Center(
                    child: Hero(
                      tag: 'app-logo',
                      child: Image.asset('assets/title.png', width: 120.w),
                    ),
                  ),

                  SizedBox(height: 40.h),

                  Row(
                    children: [
                      Text(
                        'Hi, Welcome!  ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 28.sp,
                          color: AppColors.loaderGreen,
                        ),
                      ),
                      Image.asset(
                        'assets/images/hand.png',
                        height: 30.h,
                        width: 40.h,
                      ),
                    ],
                  ),

                  SizedBox(height: 15.h),

                  Text(
                    'Email',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 5.h),

                  AppTextField(
                    controller: userNameController,
                    hintText: 'Email',
                    isObscure: false,
                    icon: null,
                  ),

                  SizedBox(height: 15.h),

                  Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 5.h),

                  AppTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    isObscure: true,
                    icon: Icons.remove_red_eye,
                  ),

                  SizedBox(height: 15.h),

                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => goToForgotPassword(context),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.darkGrey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 25.h),

                  GestureDetector(
                    onTap: () => _handleLogin(authState),
                    child: AppButton(
                      text: _getButtonText(authState),
                      loading: authState is AuthLoading,
                    ),
                  ),

                  SizedBox(height: 20.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an Account?"),
                      SizedBox(width: 5.w),
                      GestureDetector(
                        onTap: () => goToSignup(context),
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: AppColors.titleColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

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

  // -------------------------------
  // HANDLE LOGIN ACTION
  // -------------------------------
  void _handleLogin(AuthState state) {
    final username = userNameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }

    ref
        .read(authProvider.notifier)
        .login(username: username, password: password);
  }

  // -------------------------------
  // AUTH STATE CHANGES
  // -------------------------------
  void _handleAuthState(AuthState state) {
    if (state is Authenticated) {
      // Handle post-login redirect
      final redirectPath = widget.redirectTo;

      if (redirectPath != null && redirectPath.isNotEmpty) {
        // Decode and navigate to intended destination
        final decodedPath = Uri.decodeComponent(redirectPath);
        context.go(decodedPath);
      } else {
        // Default: go to home
        goToHome(context);
      }
    }

    if (state is AuthError) {
      _showErrorDialog(state.failure);
    }
  }

  // -------------------------------
  // HELPERS
  // -------------------------------
  String _getButtonText(AuthState state) {
    if (state is AuthLoading) return 'Signing In...';
    return 'Sign In';
  }

  void _showSnack(String msg) {
    AppSnackbar.error(context, msg);
  }

  void _showErrorDialog(Failure failure) {
    AppSnackbar.error(context, failure.message);
  }
}
