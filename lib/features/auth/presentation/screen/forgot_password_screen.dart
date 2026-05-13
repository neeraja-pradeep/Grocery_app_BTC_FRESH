import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/utils/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../application/providers/forgot_password_provider.dart';
import '../../application/states/forgot_password_state.dart';
import '../components/number_filed.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _mobileController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty) {
      AppSnackbar.error(context, 'Please enter your mobile number');
      return;
    }

    await ref
        .read(forgotPasswordProvider.notifier)
        .sendOtp('+91$mobile');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ForgotPasswordState>(forgotPasswordProvider, (prev, next) {
      if (!mounted) return;
      if (next is FpOtpSent) {
        goToForgotPasswordOtp(context, mobileNumber: next.phone);
      } else if (next is FpError) {
        AppSnackbar.error(context, next.message);
      }
    });

    final isLoading = ref.watch(forgotPasswordProvider) is FpLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),

                  Text(
                    'Forgot Password',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28.sp,
                      color: AppColors.titleColor,
                    ),
                  ),

                  SizedBox(height: 40.h),

                  Text(
                    'Mobile Number',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  MobileNumberField(
                    controller: _mobileController,
                    enabled: !isLoading,
                  ),

                  SizedBox(height: 30.h),

                  GestureDetector(
                    onTap: isLoading ? null : _handleSendCode,
                    child: AppButton(
                      text: isLoading ? 'Sending...' : 'Send Code',
                      loading: isLoading,
                    ),
                  ),

                  SizedBox(height: 60.h),

                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 30.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Remember your password? ',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.titleColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
}
