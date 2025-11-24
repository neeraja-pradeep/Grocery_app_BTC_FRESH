// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/app/router/app_router.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/utils/app_button.dart';
import 'package:grocery_app/core/utils/app_text_field.dart';
import 'package:grocery_app/features/auth/application/providers/auth_provider.dart';
import 'package:grocery_app/features/auth/application/states/auth_state.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 40),
            Center(child: Image.asset('assets/logo.png', width: 130)),
            const SizedBox(height: 10),

            const Text(
              'Sign up',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 35,
                color: AppColors.titleColor,
              ),
            ),

            const SizedBox(height: 15),

            const Text("Name", style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 5),
            AppTextField(
              controller: nameController,
              hintText: "Name",
              icon: null,
              isObscure: false,
            ),

            const SizedBox(height: 15),

            const Text(
              "Mobile Number",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 5),
            AppTextField(
              controller: numberController,
              hintText: "Mobile Number",
              icon: null,
              isObscure: false,
            ),

            const SizedBox(height: 15),

            const Text(
              "Create a password",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 5),
            AppTextField(
              controller: passwordController,
              hintText: "Must be 8 Characters",
              icon: Icons.remove_red_eye,
              isObscure: true,
            ),

            const SizedBox(height: 15),

            // Last Name
            const Text(
              "Confirm Password",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 5),
            AppTextField(
              controller: confirmPasswordController,
              hintText: "Confirm Password",
              icon: Icons.remove_red_eye,
              isObscure: true,
            ),

            const SizedBox(height: 25),

            // SIGN UP BUTTON
            GestureDetector(
              onTap: () => _handleSignup(authState),
              child: AppButton(
                text: authState is AuthLoading
                    ? "Creating Account..."
                    : "Sign Up",
                loading: authState is AuthLoading,
              ),
            ),

            const SizedBox(height: 20),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account?"),
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: () => goToLogin(context),
                  child: const Text(
                    "Log In",
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
    );
  }

  void _handleSignup(AuthState state) {
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (password != confirm) {
      _showError("Passwords do not match");
      return;
    }

    if ([password].any((e) => e.isEmpty)) {
      _showError("All fields are required");
      return;
    }

    ref
        .read(authProvider.notifier)
        .signup(
          username: widget.username,
          email: widget.email,
          firstName: widget.first,
          lastName: widget.last,
          phoneNumber: "+91${widget.number}",
          password: password,
          confirmPassword: confirm,
        );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
