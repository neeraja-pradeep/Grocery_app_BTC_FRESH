import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/app/router/app_router.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/utils/app_button.dart';
import 'package:grocery_app/core/utils/app_text_field.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final useridController = TextEditingController();
  final emailController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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

            // USER ID
            _label("User ID"),
            const SizedBox(height: 5),
            AppTextField(
              controller: useridController,
              hintText: "User ID",
              icon: null,
              isObscure: false,
            ),

            const SizedBox(height: 15),

            // EMAIL
            _label("Email"),
            const SizedBox(height: 5),
            AppTextField(
              controller: emailController,
              hintText: "Email",
              icon: null,
              isObscure: false,
            ),

            const SizedBox(height: 15),

            // PHONE NUMBER
            _label("Phone Number"),
            const SizedBox(height: 5),
            AppTextField(
              controller: phoneNumberController,
              icon: null,
              isObscure: false,
              hintText: "Phone Number",
            ),

            const SizedBox(height: 15),

            // First Name
            _label("First Name"),
            const SizedBox(height: 5),
            AppTextField(
              controller: firstNameController,
              hintText: "First Name",
              icon: null,
              isObscure: false,
            ),

            const SizedBox(height: 15),

            // Last Name
            _label("Last Name"),
            const SizedBox(height: 5),
            AppTextField(
              controller: lastNameController,
              hintText: "Last Name",
              icon: null,
              isObscure: false,
            ),

            const SizedBox(height: 20),
            // SIGN UP BUTTON
            GestureDetector(
              onTap: () => {_handleSignup()},
              child: const AppButton(text: 'Sign Up'),
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

  Widget _label(String text) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w500));

  void _handleSignup() {
    final username = useridController.text.trim();
    final email = emailController.text.trim();
    final number = phoneNumberController.text.trim();
    final first = firstNameController.text.trim();
    final last = lastNameController.text.trim();

    if ([username, email, number, first].any((e) => e.isEmpty)) {
      _showError("All fields are required");
      return;
    }
    goToSignWithPass(
      context,
      username: username,
      email: email,
      first: first,
      last: last,
      number: number,
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
