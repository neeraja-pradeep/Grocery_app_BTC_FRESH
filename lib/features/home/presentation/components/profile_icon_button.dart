// features/home/presentation/components/profile_icon_button.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../profile/application/providers/profile_provider.dart';

class ProfileIconButton extends ConsumerStatefulWidget {
  final VoidCallback onProfileTap;

  const ProfileIconButton({super.key, required this.onProfileTap});

  @override
  ConsumerState<ProfileIconButton> createState() => _ProfileIconButtonState();
}

class _ProfileIconButtonState extends ConsumerState<ProfileIconButton> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final hasProfile = ref.read(profileControllerProvider).profile != null;
      if (!hasProfile) {
        ref.read(profileControllerProvider.notifier).fetchProfile();
      }
    });
  }

  Widget _fallbackIcon() => Image.asset(
    'assets/profile_icon.png',
    height: 32.h,
    width: 32.w,
    color: const Color(0xff016064),
  );

  @override
  Widget build(BuildContext context) {
    final profileImageUrl = ref.watch(
      profileControllerProvider.select((s) => s.profile?.profileImageUrl),
    );

    final hasImage =
        profileImageUrl != null && profileImageUrl.trim().isNotEmpty;

    return GestureDetector(
      onTap: widget.onProfileTap,
      child: hasImage
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: profileImageUrl,
                height: 32.h,
                width: 32.w,
                fit: BoxFit.cover,
                memCacheWidth: 96,
                maxWidthDiskCache: 1080,
                errorWidget: (context, url, error) => _fallbackIcon(),
              ),
            )
          : _fallbackIcon(),
    );
  }
}
