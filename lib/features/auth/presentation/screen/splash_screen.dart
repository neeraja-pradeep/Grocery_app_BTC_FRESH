import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/widgets/app_background.dart';

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

  // All users land on home after the splash animation. Login is optional and
  // only enforced later on protected routes (cart, checkout, etc.).
  void _navigateToHome() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    goToHome(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: kPatternBackgroundDecoration,
        child: Lottie.asset(
          'assets/lottie/biker.json',
          controller: _controller,
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.contain,
          onLoaded: (composition) {
            _controller
              ..duration = composition.duration * 0.25
              ..forward().whenComplete(() {
                if (mounted) _navigateToHome();
              });
          },
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
