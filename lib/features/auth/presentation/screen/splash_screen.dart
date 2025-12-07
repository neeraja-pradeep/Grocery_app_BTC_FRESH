// lib/features/auth/presentation/screen/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';

/// Splash screen - First screen shown to users with video
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Duration to show splash screen before navigating
  static const Duration splashDuration = Duration(seconds: 5);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _navigateAfterDelay();
  }

  Future<void> _initializeVideo() async {
    _videoController = VideoPlayerController.asset(
      'assets/videos/deliveryBoy.mp4',
    );
    await _videoController.initialize();
    _videoController.setLooping(true);
    _videoController.play();
    setState(() {
      _isInitialized = true;
    });
  }

  void _navigateAfterDelay() {
    Future.delayed(SplashScreen.splashDuration, () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRouter.loginIntro);
      }
    });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/background_graphics.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  // Spacer to push content to center
                  SizedBox(height: 24.h),
                  const Spacer(),

                  // Delivery video
                  SizedBox(
                    height: 131.h,
                    width: 196.w,
                    child: _isInitialized
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: AspectRatio(
                              aspectRatio: _videoController.value.aspectRatio,
                              child: VideoPlayer(_videoController),
                            ),
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),

                  SizedBox(height: 24.h),

                  // App logo/title
                  Image.asset(
                    'assets/title.png',
                    height: 40.h,
                    fit: BoxFit.contain,
                  ),

                  // Main heading
                  Text(
                    'Get your groceries\ndelivered to your home',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.green100,
                      height: 1.2,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Subtitle
                  Text(
                    'The best delivery app in town for\ndelivering your daily fresh groceries',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey,
                      height: 1.4,
                    ),
                  ),

                  // Spacer to push content up from bottom
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
