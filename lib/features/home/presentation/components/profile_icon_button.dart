// features/home/presentation/components/profile_icon_button.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ProfileIconButton extends StatelessWidget {
  final VoidCallback onProfileTap;

  const ProfileIconButton({super.key, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onProfileTap,
      child: Image.asset(
        'assets/profile_icon.png',
        height: 32.h,
        width: 32.w,
        color: const Color(0xff016064),
      ),

      // Placeholder for fetching minimal profile summary
    );
  }
}
