import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../../app/router/app_router.dart';
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
      goToHome(context);
    } else if (authState is AuthChecking) {
      // wait for listener
    } else {
      _hasNavigated = true;
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
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          image: DecorationImage(
            image: AssetImage('assets/bg.png'),
            fit: BoxFit.cover,
            opacity: 0.5,
          ),
        ),
        child: Center(
          child: Lottie.asset(
            'assets/lottie/biker.json',
            controller: _controller,
            width: double.infinity,
            height: double.infinity,
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
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
