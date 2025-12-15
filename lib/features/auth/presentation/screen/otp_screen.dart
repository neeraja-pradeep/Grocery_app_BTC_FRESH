import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../application/providers/auth_provider.dart';
import '../../application/states/auth_state.dart';
import '../components/number_filed.dart';
import '../components/otp_filed.dart';

class OTPScreen extends ConsumerStatefulWidget {
  const OTPScreen({super.key});

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final TextEditingController numberController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool showOtpField = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen to AuthState changes
    ref.listen<AuthState>(authProvider, (prev, next) {
      _handleAuthStateChange(next);
    });

    return Scaffold(
      body: Center(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              top: 16.h,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16.h,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Hero(
                      tag: 'app-logo',
                      child: Image.asset('assets/title.png', width: 120.w),
                    ),
                  ),

                  SizedBox(height: 10.h),

                  Text(
                    'Hi, Welcome!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 35.sp,
                      color: const Color.fromARGB(255, 85, 89, 90),
                    ),
                  ),

                  SizedBox(height: 15.h),

                  const Text(
                    'Mobile Number',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 5.h),

                  MobileNumberField(
                    controller: numberController,
                    enabled: true,
                  ),

                  SizedBox(height: 25.h),

                  if (showOtpField) ...[
                    const Text(
                      'Enter OTP',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 5.h),

                    OtpField(controller: otpController, enabled: true),
                    SizedBox(height: 20.h),
                  ],

                  // MAIN BUTTON
                  GestureDetector(
                    onTap: () => _handleButtonPress(authState),
                    child: AppButton(
                      text: _getButtonText(authState),
                      loading: _isProcessing(authState),
                    ),
                  ),

                  SizedBox(height: 30.h),

                  GestureDetector(
                    onTap: () => goToLogin(context),
                    child: Container(
                      height: 60.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 225, 249, 182),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Text(
                          'Sign In With Password',
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.titleColor,
                          ),
                        ),
                      ),
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
                            fontWeight: FontWeight.bold,
                            color: AppColors.titleColor,
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

  // -----------------------------------------------------
  // STATE CHANGE HANDLER
  // -----------------------------------------------------
  void _handleAuthStateChange(AuthState state) {
    if (state is OtpSent) {
      setState(() => showOtpField = true);
      otpController.clear();
      FocusScope.of(context).nextFocus();
    }

    if (state is Authenticated) {
      if (state.isNewUser) {
        // goToAddress(context,);
      } else {
        goToHome(context);
      }
    }

    if (state is AuthError) {
      _showErrorDialog(state.failure);
    }
  }

  // -----------------------------------------------------
  // BUTTON HANDLER
  // -----------------------------------------------------
  void _handleButtonPress(AuthState state) {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return; // STOP if text fields are invalid
    final mobile = numberController.text.trim();
    final otp = otpController.text.trim();

    if (mobile.isEmpty) {
      _showSnack('Enter mobile number');
      return;
    }

    if (!showOtpField) {
      ref.read(authProvider.notifier).sendOtp('+91$mobile');
    } else {
      if (otp.isEmpty) {
        _showSnack('Enter OTP');
        return;
      }
      ref.read(authProvider.notifier).verifyOtp('+91$mobile', otp);
    }
  }

  // -----------------------------------------------------
  // HELPERS
  // -----------------------------------------------------
  bool _isProcessing(AuthState state) {
    return state is OtpSending || state is OtpVerifying;
  }

  String _getButtonText(AuthState state) {
    if (state is OtpSending) return 'Sending OTP...';
    if (state is OtpVerifying) return 'Verifying...';
    return showOtpField ? 'Verify OTP' : 'Get OTP';
  }

  void _showSnack(String msg) {
    AppSnackbar.error(context, msg);
  }

  void _showErrorDialog(Failure failure) {
    AppSnackbar.error(context, failure.message);
  }
}
