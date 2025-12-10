import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../application/providers/auth_provider.dart';
import '../../application/states/auth_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);
  }

  void _navigateBasedOnAuthState() {
    if (_hasNavigated) return;

    final authState = ref.read(authProvider);

    if (authState is Authenticated) {
      _hasNavigated = true;
      Future.delayed(const Duration(seconds: 2));
      goToHome(context);
    } else if (authState is AuthChecking) {
      // wait for listener
    } else {
      _hasNavigated = true;
      Future.delayed(const Duration(seconds: 2));
      goToOTP(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (!_hasNavigated && next is! AuthChecking && !_controller.isAnimating) {
        _navigateBasedOnAuthState();
      }
    });

    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Hero(
              tag: 'delivery_boy',
              child: Lottie.asset(
                'assets/lottie/delivery_boy.json',
                controller: _controller,
                width: 200.w,
                height: 200.h,
                fit: BoxFit.contain,
                onLoaded: (composition) {
                  _controller
                    ..duration = composition.duration
                    ..forward().whenComplete(() {
                      if (mounted) {
                        _navigateBasedOnAuthState();
                      }
                    });
                },
              ),
            ),

            SizedBox(height: 10.h),

            Text(
              'Get your groceries delivered to your home',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 30.sp,
                color: AppColors.titleColor,
              ),
            ),

            SizedBox(height: 20.h),

            Text(
              'The best delivery app in town\nfor delivering your daily fresh groceries',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),

            SizedBox(height: 100.h),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
