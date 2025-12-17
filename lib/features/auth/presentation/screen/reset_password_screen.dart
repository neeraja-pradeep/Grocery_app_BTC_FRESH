import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/utils/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../application/providers/auth_repository_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String mobileNumber;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.mobileNumber,
    required this.otp,
  });

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty || confirmPassword.isEmpty) {
      _showSnack('Please fill all fields');
      return;
    }

    if (password != confirmPassword) {
      _showSnack('Passwords do not match');
      return;
    }

    if (password.length < 6) {
      _showSnack('Password must be at least 6 characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(authRepositoryProvider);

      final result = await repo.resetPassword(newPassword: password);

      if (!mounted) return;

      result.fold((failure) => _showSnack(failure.message), (message) {
        goToPasswordChanged(context);
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    AppSnackbar.error(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppColors.titleColor,
            size: 20.sp,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Image.asset('assets/images/star.png', height: 20.h, width: 20.w),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16.w,
                right: 16.w,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20.h),

                    Text(
                      'Reset Password',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28.sp,
                        color: AppColors.titleColor,
                      ),
                    ),

                    SizedBox(height: 12.h),

                    Text(
                      'Please type something you’ll remember',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),

                    SizedBox(height: 40.h),

                    // New Password Field
                    Text(
                      'New Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'Enter new password',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 14.sp,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: const BorderSide(
                            color: AppColors.borderColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: const BorderSide(
                            color: AppColors.borderColor,
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Password is required';
                        }
                        if (value!.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 20.h),

                    // Confirm Password Field
                    Text(
                      'Confirm New Password',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.sp,
                      ),
                    ),
                    SizedBox(height: 8.h),

                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        hintText: 'Confirm your password',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 14.sp,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: const BorderSide(
                            color: AppColors.borderColor,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: const BorderSide(
                            color: AppColors.borderColor,
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            );
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 40.h),

                    GestureDetector(
                      onTap: _isLoading ? null : _handleResetPassword,
                      child: AppButton(
                        text: _isLoading ? 'Resetting...' : 'Reset Password',
                        loading: _isLoading,
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Password requirements hint
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.green10,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Password must:',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 4.h),
                          _buildRequirement('Be at least 6 characters long'),
                          _buildRequirement('Match the confirm password field'),
                        ],
                      ),
                    ),
                    SizedBox(height: 130.h),
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
                              color: AppColors.black,
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
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: EdgeInsets.only(top: 2.h),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 14.sp,
            color: AppColors.borderColor,
          ),
          SizedBox(width: 6.w),
          Text(
            text,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
