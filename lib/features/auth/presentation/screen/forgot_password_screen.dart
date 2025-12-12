import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/utils/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../infrastructure/data_sources/remote/auth_api.dart';
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
  bool _isLoading = false;

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final mobile = _mobileController.text.trim();
    if (mobile.isEmpty) {
      _showSnack('Please enter your mobile number');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authApi = ref.read(authApiProvider);
      final phoneWithCountryCode = '+91$mobile';

      final message = await authApi.sendOtp(phoneNumber: phoneWithCountryCode);

      if (!mounted) return;

      if (message == 'OTP sent successfully') {
        goToForgotPasswordOtp(context, mobileNumber: phoneWithCountryCode);
      } else {
        _showSnack(message);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnack(String msg) {
    AppSnackbar.error(context, msg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
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

                SizedBox(height: 12.h),

                Text(
                  'Enter your mobile number to receive a verification code',
                  style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
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
                  enabled: !_isLoading,
                ),

                SizedBox(height: 40.h),

                GestureDetector(
                  onTap: _isLoading ? null : _handleSendCode,
                  child: AppButton(
                    text: _isLoading ? 'Sending...' : 'Send Code',
                    loading: _isLoading,
                  ),
                ),

                SizedBox(height: 100.h),

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
    );
  }
}
