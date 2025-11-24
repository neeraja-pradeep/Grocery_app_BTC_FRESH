import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/app/router/app_router.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/error/failure.dart';
import 'package:grocery_app/core/utils/app_button.dart';
import 'package:grocery_app/core/utils/app_text_field.dart';
import 'package:grocery_app/features/auth/application/providers/auth_provider.dart';
import 'package:grocery_app/features/auth/application/states/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                "User ID",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 5),

              AppTextField(
                controller: userNameController,
                hintText: "User ID",
                isObscure: false,
                icon: null,
              ),

              const SizedBox(height: 15),

              const Text(
                "Password",
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 5),

              AppTextField(
                controller: passwordController,
                hintText: "Password",
                isObscure: true,
                icon: Icons.remove_red_eye,
              ),

              const SizedBox(height: 25),

              GestureDetector(
                onTap: () => _handleLogin(authState),
                child: AppButton(
                  text: _getButtonText(authState),
                  loading: authState is AuthLoading,
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
                        color: AppColors.titleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Center(
                child: Text(
                  "Skip",
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: AppColors.titleColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
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
      _showSnack("Please fill all fields");
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
      goToHome(context);
    }

    if (state is AuthError) {
      _showErrorDialog(state.failure);
    }
  }

  // -------------------------------
  // HELPERS
  // -------------------------------
  String _getButtonText(AuthState state) {
    if (state is AuthLoading) return "Signing In...";
    return "Sign In";
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showErrorDialog(Failure failure) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Login Failed"),
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
