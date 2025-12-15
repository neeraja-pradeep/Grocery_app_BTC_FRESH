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
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _borderController;
  late Animation<double> _borderAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this);

    // Border animation controller
    _borderController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _borderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _borderController, curve: Curves.easeInOut),
    );

    // Start border animation
    _borderController.forward();
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
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 1),

              // Lottie Animation
              Center(
                child: AnimatedBuilder(
                  animation: _borderAnimation,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _AnimatedBorderPainter(
                        progress: _borderAnimation.value,
                        color: const Color(0xFF64DD17), // Bright green
                        borderRadius: 20.r,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.titleColor.withValues(alpha: 0.03),
                              AppColors.titleColor.withValues(alpha: 0.01),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.titleColor.withValues(
                                alpha: 0.04,
                              ),
                              blurRadius: 15,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Hero(
                          tag: 'delivery_boy',
                          child: Lottie.asset(
                            'assets/lottie/delivery_boy.json',
                            controller: _controller,
                            width: 280.w,
                            height: 260.h,
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
                  },
                ),
              ),

              SizedBox(height: 40.h),

              // Main Title
              Text(
                'Get your groceries delivered to your home',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26.sp,
                  color: AppColors.titleColor,
                  height: 1.3,
                ),
              ),

              SizedBox(height: 16.h),

              // Subtitle
              Text(
                'The best delivery app in town\nfor delivering your daily fresh groceries',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _borderController.dispose();
    super.dispose();
  }
}

/// Custom painter for animated border
class _AnimatedBorderPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double borderRadius;

  _AnimatedBorderPainter({
    required this.progress,
    required this.color,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final path = Path()..addRRect(rrect);
    final pathMetrics = path.computeMetrics().first;
    final extractPath = pathMetrics.extractPath(
      0.0,
      pathMetrics.length * progress,
    );

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(_AnimatedBorderPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
