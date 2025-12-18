import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../application/providers/auth_provider.dart';
import '../../application/states/auth_state.dart';
import '../components/number_filed.dart';

class OTPScreen extends ConsumerStatefulWidget {
  const OTPScreen({super.key});

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final TextEditingController numberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Individual controllers for each OTP digit
  final List<TextEditingController> _otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  // Focus nodes for each OTP field
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool showOtpField = false;
  bool _hasOtpError = false;
  String _otpErrorMessage = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to track OTP input changes
    for (var controller in _otpControllers) {
      controller.addListener(_onOtpChanged);
    }
  }

  @override
  void dispose() {
    numberController.dispose();
    for (var controller in _otpControllers) {
      controller.removeListener(_onOtpChanged);
      controller.dispose();
    }
    for (var node in _otpFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  /// Get the complete OTP string from all controllers
  String get _completeOtp {
    return _otpControllers.map((c) => c.text).join();
  }

  /// Check if OTP is complete (all 6 digits entered)
  bool get _isOtpComplete {
    return _completeOtp.length == 6 &&
        RegExp(r'^\d{6}$').hasMatch(_completeOtp);
  }

  /// Called when any OTP digit changes
  void _onOtpChanged() {
    // Clear error state when user starts editing
    if (_hasOtpError) {
      setState(() {
        _hasOtpError = false;
        _otpErrorMessage = '';
      });
    }
    // Trigger rebuild to update button state
    setState(() {});
  }

  /// Get masked phone number for display (e.g., "******7890")
  String get _maskedPhoneNumber {
    final number = numberController.text.trim();
    if (number.length < 4) return number;
    final visibleDigits = number.substring(number.length - 4);
    return '******$visibleDigits';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen to AuthState changes
    ref.listen<AuthState>(authProvider, (prev, next) {
      _handleAuthStateChange(next);
    });

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(8.w),
        child: Center(
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
                    SizedBox(height: 60.h),
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
                          'Hi, Welcome!',
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

                    const Text(
                      'Mobile Number',
                      style: TextStyle(fontWeight: FontWeight.w400),
                    ),
                    SizedBox(height: 5.h),

                    MobileNumberField(
                      controller: numberController,
                      enabled: !showOtpField, // Disable when OTP is shown
                    ),

                    SizedBox(height: 10.h),

                    if (showOtpField) ...[
                      // Instruction text with masked phone number
                      _buildOtpInstructions(),
                      SizedBox(height: 15.h),

                      // Individual OTP digit fields
                      _buildOtpInputFields(),

                      // Error message display
                      if (_hasOtpError) ...[
                        SizedBox(height: 8.h),
                        _buildOtpErrorMessage(),
                      ],

                      SizedBox(height: 15.h),

                      // Resend OTP option
                      _buildResendOption(authState),

                      SizedBox(height: 20.h),
                    ],

                    // MAIN BUTTON
                    _buildMainButton(authState),

                    SizedBox(height: 10.h),

                    GestureDetector(
                      onTap: () => goToLogin(context),
                      child: Container(
                        height: 60.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.lightGreen,
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Center(
                          child: Text(
                            'Sign In With Password',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
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
                        const Text(
                          "Don't have an Account?",
                          style: TextStyle(color: AppColors.darkGrey),
                        ),
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
      ),
    );
  }

  /// Build the OTP instruction text with masked phone number
  Widget _buildOtpInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter OTP',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
            color: AppColors.black,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Enter the 6-digit OTP sent to +91 $_maskedPhoneNumber',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13.sp,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }

  /// Build the individual OTP input fields with auto-focus behavior
  Widget _buildOtpInputFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 48.w,
          height: 56.h,
          child: KeyboardListener(
            focusNode: FocusNode(),
            onKeyEvent: (event) {
              // Handle backspace on empty field
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace &&
                  _otpControllers[index].text.isEmpty &&
                  index > 0) {
                _otpFocusNodes[index - 1].requestFocus();
              }
            },
            child: TextFormField(
              controller: _otpControllers[index],
              focusNode: _otpFocusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: _hasOtpError ? Colors.red : AppColors.black,
              ),
              decoration: InputDecoration(
                counterText: '', // Hide character counter
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: _hasOtpError
                    ? Colors.red.withValues(alpha: 0.05)
                    : AppColors.white,
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(
                    color: _hasOtpError ? Colors.red : AppColors.loaderGreen,
                    width: 2,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: BorderSide(
                    color: _hasOtpError ? Colors.red : AppColors.borderColor,
                    width: 1,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.r),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(1),
              ],
              onChanged: (value) => _handleOtpDigitChange(index, value),
              onTap: () {
                // Select all text when tapping on a field
                _otpControllers[index].selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _otpControllers[index].text.length,
                );
              },
            ),
          ),
        );
      }),
    );
  }

  /// Handle OTP digit input change with auto-focus navigation
  void _handleOtpDigitChange(int index, String value) {
    if (value.isNotEmpty) {
      // Move to next field if not the last one
      if (index < 5) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        // Last field - unfocus keyboard
        _otpFocusNodes[index].unfocus();
      }
    }
  }

  /// Build error message display for OTP
  Widget _buildOtpErrorMessage() {
    return Row(
      children: [
        Icon(Icons.error_outline, size: 16.sp, color: Colors.red),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            _otpErrorMessage,
            style: TextStyle(
              color: Colors.red,
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }

  /// Build resend OTP option
  Widget _buildResendOption(AuthState authState) {
    final isResending = authState is OtpSending;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the OTP? ",
          style: TextStyle(color: AppColors.grey, fontSize: 13.sp),
        ),
        GestureDetector(
          onTap: isResending ? null : _handleResendOtp,
          child: Text(
            isResending ? 'Sending...' : 'Resend OTP',
            style: TextStyle(
              color: isResending ? AppColors.grey : AppColors.loaderGreen,
              fontWeight: FontWeight.w600,
              fontSize: 13.sp,
            ),
          ),
        ),
      ],
    );
  }

  /// Handle resend OTP action
  void _handleResendOtp() {
    final mobile = numberController.text.trim();
    if (mobile.isEmpty || mobile.length != 10) {
      _showSnack('Invalid mobile number');
      return;
    }

    // Clear existing OTP fields
    _clearOtpFields();

    // Resend OTP
    ref.read(authProvider.notifier).sendOtp('+91$mobile');
  }

  /// Clear all OTP input fields
  void _clearOtpFields() {
    for (var controller in _otpControllers) {
      controller.clear();
    }
    setState(() {
      _hasOtpError = false;
      _otpErrorMessage = '';
    });
  }

  /// Build the main action button with proper state handling
  Widget _buildMainButton(AuthState authState) {
    final isProcessing = _isProcessing(authState);
    final buttonText = _getButtonText(authState);

    // Determine if button should be enabled
    bool isEnabled = true;

    if (isProcessing || _isSubmitting) {
      isEnabled = false;
    } else if (showOtpField) {
      // When OTP field is shown, only enable if OTP is complete
      isEnabled = _isOtpComplete;
    } else {
      // When showing phone input, enable if valid phone number
      final phone = numberController.text.trim();
      isEnabled = phone.length == 10 && RegExp(r'^\d{10}$').hasMatch(phone);
    }

    return GestureDetector(
      onTap: isEnabled ? () => _handleButtonPress(authState) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 55.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: isEnabled
              ? AppColors.borderColor
              : AppColors.borderColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: isProcessing || _isSubmitting
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.0,
                    color: Colors.white,
                  ),
                )
              : Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
      setState(() {
        showOtpField = true;
        _isSubmitting = false;
      });
      _clearOtpFields();

      // Focus on first OTP field after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _otpFocusNodes[0].requestFocus();
        }
      });

      // Show success message
      AppSnackbar.success(context, 'OTP sent successfully');
    }

    if (state is Authenticated) {
      setState(() => _isSubmitting = false);
      if (state.isNewUser) {
        // goToAddress(context,);
      } else {
        goToHome(context);
      }
    }

    if (state is AuthError) {
      setState(() => _isSubmitting = false);
      _handleAuthError(state);
    }

    // Handle OtpSending state
    if (state is OtpSending) {
      setState(() => _isSubmitting = true);
    }

    // Handle OtpVerifying state
    if (state is OtpVerifying) {
      setState(() => _isSubmitting = true);
    }
  }

  /// Handle authentication errors with appropriate UI feedback
  void _handleAuthError(AuthError state) {
    final failure = state.failure;

    // Check if it's an OTP-related error
    final errorMessage = failure.message.toLowerCase();
    final isOtpError =
        errorMessage.contains('otp') ||
        errorMessage.contains('invalid') ||
        errorMessage.contains('expired') ||
        errorMessage.contains('incorrect') ||
        errorMessage.contains('verification');

    if (showOtpField && isOtpError) {
      // Show inline OTP error
      setState(() {
        _hasOtpError = true;
        _otpErrorMessage = _getOtpErrorMessage(failure);
      });

      // Allow user to re-edit OTP - focus on first field
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _otpFocusNodes[0].requestFocus();
        }
      });
    } else {
      // Show snackbar for other errors
      AppSnackbar.error(context, failure.message);
    }
  }

  /// Get user-friendly OTP error message
  String _getOtpErrorMessage(Failure failure) {
    final message = failure.message.toLowerCase();

    if (message.contains('expired')) {
      return 'OTP has expired. Please request a new one.';
    } else if (message.contains('invalid') || message.contains('incorrect')) {
      return 'Invalid OTP. Please check and try again.';
    } else if (message.contains('attempts') || message.contains('limit')) {
      return 'Too many attempts. Please try again later.';
    } else {
      return failure.message;
    }
  }

  // -----------------------------------------------------
  // BUTTON HANDLER
  // -----------------------------------------------------
  void _handleButtonPress(AuthState state) {
    // Prevent multiple submissions
    if (_isSubmitting || _isProcessing(state)) return;

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid && !showOtpField) return;

    final mobile = numberController.text.trim();

    if (mobile.isEmpty || mobile.length != 10) {
      _showSnack('Please enter a valid 10-digit mobile number');
      return;
    }

    if (!showOtpField) {
      // Request OTP
      setState(() => _isSubmitting = true);
      ref.read(authProvider.notifier).sendOtp('+91$mobile');
    } else {
      // Verify OTP
      final otp = _completeOtp;

      if (otp.length != 6) {
        setState(() {
          _hasOtpError = true;
          _otpErrorMessage = 'Please enter all 6 digits';
        });
        return;
      }

      if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
        setState(() {
          _hasOtpError = true;
          _otpErrorMessage = 'OTP must contain only digits';
        });
        return;
      }

      setState(() => _isSubmitting = true);
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
}
