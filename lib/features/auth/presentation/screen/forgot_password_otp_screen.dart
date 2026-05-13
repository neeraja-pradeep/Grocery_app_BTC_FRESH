import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/utils/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../application/providers/forgot_password_provider.dart';
import '../../application/states/forgot_password_state.dart';

class ForgotPasswordOtpScreen extends ConsumerStatefulWidget {
  final String mobileNumber;

  const ForgotPasswordOtpScreen({super.key, required this.mobileNumber});

  @override
  ConsumerState<ForgotPasswordOtpScreen> createState() =>
      _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState
    extends ConsumerState<ForgotPasswordOtpScreen> {
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _timerSeconds = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _timerSeconds = 60;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  Future<void> _handleResendCode() async {
    if (!_canResend) return;
    await ref.read(forgotPasswordProvider.notifier).resendOtp();
    if (mounted) {
      _startTimer();
      for (final controller in _otpControllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
    }
  }

  String get _formattedTime {
    final minutes = (_timerSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_timerSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _maskedMobile {
    final mobile = widget.mobileNumber;
    if (mobile.length >= 4) {
      return '******${mobile.substring(mobile.length - 4)}';
    }
    return mobile;
  }

  String get _otpValue {
    return _otpControllers.map((c) => c.text).join();
  }

  Future<void> _handleVerifyOtp() async {
    final otp = _otpValue;
    if (otp.length != 6) {
      AppSnackbar.error(context, 'Please enter complete 6-digit OTP');
      return;
    }
    await ref.read(forgotPasswordProvider.notifier).verifyOtp(otp);
  }

  void _fillOtpFields(String otp) {
    for (int i = 0; i < 6 && i < otp.length; i++) {
      _otpControllers[i].text = otp[i];
    }
    if (otp.length == 6) {
      _focusNodes[5].requestFocus();
    }
  }

  void _onOtpFieldChanged(String value, int index) {
    if (value.length > 1) {
      _fillOtpFields(value);
      return;
    }
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ForgotPasswordState>(forgotPasswordProvider, (prev, next) {
      if (!mounted) return;
      if (next is FpOtpVerified) {
        goToResetPassword(context, mobileNumber: next.phone, otp: next.otp);
      } else if (next is FpError) {
        AppSnackbar.error(context, next.message);
      }
    });

    final isLoading = ref.watch(forgotPasswordProvider) is FpLoading;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),

              Text(
                'Enter OTP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28.sp,
                  color: AppColors.titleColor,
                ),
              ),

              SizedBox(height: 12.h),

              Text(
                'We have sent a verification code to $_maskedMobile',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
              ),

              SizedBox(height: 40.h),

              AutofillGroup(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 48.w,
                      height: 56.h,
                      child: TextFormField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        enabled: !isLoading,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        autofillHints: index == 0
                            ? const [AutofillHints.oneTimeCode]
                            : null,
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.titleColor,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: const BorderSide(
                              color: AppColors.borderColor,
                              width: 2,
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
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        onChanged: (value) => _onOtpFieldChanged(value, index),
                      ),
                    );
                  }),
                ),
              ),

              SizedBox(height: 30.h),

              Center(
                child: Column(
                  children: [
                    if (!_canResend) ...[
                      Text(
                        'Resend code in',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _formattedTime,
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.titleColor,
                        ),
                      ),
                    ] else ...[
                      GestureDetector(
                        onTap: isLoading ? null : _handleResendCode,
                        child: Text(
                          'Resend Code',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.titleColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 40.h),

              GestureDetector(
                onTap: isLoading ? null : _handleVerifyOtp,
                child: AppButton(text: 'Continue', loading: isLoading),
              ),

              SizedBox(height: 100.h),

              Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: 30.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive code? ",
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      GestureDetector(
                        onTap: _canResend && !isLoading
                            ? _handleResendCode
                            : null,
                        child: Text(
                          'Resend',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: _canResend
                                ? AppColors.titleColor
                                : Colors.grey[400],
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
    );
  }
}
