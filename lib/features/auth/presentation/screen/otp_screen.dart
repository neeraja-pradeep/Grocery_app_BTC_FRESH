import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/app/router/app_router.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/error/failure.dart';
import 'package:grocery_app/core/utils/app_button.dart';
import 'package:grocery_app/features/auth/application/providers/auth_provider.dart';
import 'package:grocery_app/features/auth/application/states/auth_state.dart';
import 'package:grocery_app/features/auth/presentation/components/number_filed.dart';
import 'package:grocery_app/features/auth/presentation/components/otp_filed.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: Hero(
                  tag: 'app-logo',
                  child: Image.asset('assets/logo.png', width: 120),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Hi, Welcome!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 35,
                  color: Color.fromARGB(255, 85, 89, 90),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                "Mobile Number",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 5),

              MobileNumberField(controller: numberController, enabled: true),

              const SizedBox(height: 25),

              if (showOtpField) ...[
                const Text(
                  "Enter OTP",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 5),

                OtpField(controller: otpController, enabled: true),
                const SizedBox(height: 20),
              ],

              // MAIN BUTTON
              GestureDetector(
                onTap: () => _handleButtonPress(authState),
                child: AppButton(
                  text: _getButtonText(authState),
                  loading: _isProcessing(authState),
                ),
              ),

              const SizedBox(height: 30),

              GestureDetector(
                onTap: () => goToLogin(context),
                child: Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 225, 249, 182),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text(
                      "Sign In With Password",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.titleColor,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don't have an Account?"),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () => goToSignup(context),
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.titleColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: () {
                    goToHome(context);
                  },
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      decoration: TextDecoration.underline,
                      color: AppColors.titleColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
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
      _showSnack("Enter mobile number");
      return;
    }

    if (!showOtpField) {
      ref.read(authProvider.notifier).sendOtp("+91$mobile");
    } else {
      if (otp.isEmpty) {
        _showSnack("Enter OTP");
        return;
      }
      ref.read(authProvider.notifier).verifyOtp("+91$mobile", otp);
    }
  }

  // -----------------------------------------------------
  // HELPERS
  // -----------------------------------------------------
  bool _isProcessing(AuthState state) {
    return state is OtpSending || state is OtpVerifying;
  }

  String _getButtonText(AuthState state) {
    if (state is OtpSending) return "Sending OTP...";
    if (state is OtpVerifying) return "Verifying...";
    return showOtpField ? "Verify OTP" : "Get OTP";
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showErrorDialog(Failure failure) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error"),
        content: Text(failure.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
