import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grocery_app/app/router/app_router.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/features/auth/application/providers/auth_provider.dart';
import 'package:grocery_app/features/auth/application/states/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final authState = ref.read(authProvider);
        final isAuthenticated = authState is Authenticated;
        if (isAuthenticated) {
          goToHome(context);
        } else {
          goToOTP(context);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('assets/delivery.png', width: 200),
            Hero(
              tag: 'app-logo',
              child: Image.asset('assets/logo.png', width: 100),
            ),
            const SizedBox(height: 10),
            const Text(
              'Get your groceries delivered to your home',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,

                fontSize: 30,
                color: AppColors.titleColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'The best delivery app in town\nfor delivering your daily fresh groceries',

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
