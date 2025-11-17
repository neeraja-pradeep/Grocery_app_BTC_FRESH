// features/home/presentation/components/profile_icon_button.dart

import 'package:flutter/material.dart';

class ProfileIconButton extends StatelessWidget {
  final VoidCallback onProfileTap;

  const ProfileIconButton({super.key, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.person_2_rounded, color: Color(0xff016064)),
      onPressed: onProfileTap,
      // Placeholder for fetching minimal profile summary
    );
  }
}
