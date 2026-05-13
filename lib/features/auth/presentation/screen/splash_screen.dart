import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
  bool _animationStarted = false;
  bool _showNextButton = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  // Only auto-navigates authenticated users — unauthenticated users tap Next.
  void _navigateIfAuthenticated() {
    if (_hasNavigated) return;
    final authState = ref.read(authProvider);
    if (authState is Authenticated) {
      _hasNavigated = true;
      goToHome(context);
    }
  }

  void _onNextTapped() {
    if (_hasNavigated) return;
    _hasNavigated = true;
    goToOTP(context);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (!_hasNavigated &&
          next is Authenticated &&
          _animationStarted &&
          !_controller.isAnimating) {
        _navigateIfAuthenticated();
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
            repeat: ImageRepeat.repeat,
            opacity: 0.7,
          ),
        ),
        child: Stack(
          children: [
            Lottie.asset(
              'assets/lottie/biker.json',
              controller: _controller,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              onLoaded: (composition) {
                _animationStarted = true;
                _controller
                  ..duration = composition.duration * 0.25
                  ..forward().whenComplete(() {
                    if (mounted) {
                      _navigateIfAuthenticated();
                      setState(() => _showNextButton = true);
                    }
                  });
              },
            ),

            Positioned(
              bottom: 80.h,
              left: 20.w,
              right: 20.w,
              child: AnimatedOpacity(
                opacity: _showNextButton ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeIn,
                child: AnimatedSlide(
                  offset: _showNextButton ? Offset.zero : const Offset(0, 0.3),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOut,
                  child: GestureDetector(
                    onTap: _onNextTapped,
                    child: Container(
                      height: 56.h,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Center(
                        child: Text(
                          'Next',
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
