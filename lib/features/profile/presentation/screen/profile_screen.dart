import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/colors.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../application/providers/profile_provider.dart';
import '../components/profile_header.dart';
import '../components/profile_menu_item.dart';
import '../components/profile_section_header.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(profileControllerProvider.notifier).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.black,
            size: 20.sp,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'My Profile',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: profileState.isLoading && !profileState.hasData
            ? const Center(child: CircularProgressIndicator())
            : profileState.isError && !profileState.hasData
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      profileState.errorMessage ?? 'Something went wrong',
                      style: TextStyle(fontSize: 14.sp, color: AppColors.grey),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.h16,
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(profileControllerProvider.notifier)
                            .fetchProfile();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                color: AppColors.green,
                onRefresh: () async {
                  await ref
                      .read(profileControllerProvider.notifier)
                      .refreshProfile();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSpacing.h16,
                      // Stale data warning banner
                      if (profileState.isStale)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.w),
                          margin: EdgeInsets.only(bottom: 16.h),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange.shade700,
                                size: 20.sp,
                              ),
                              AppSpacing.w12,
                              Expanded(
                                child: Text(
                                  'Showing offline data. Pull to refresh for latest updates.',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Colors.orange.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ProfileHeader(
                        fullName: profileState.profile?.fullName ?? 'User',
                        mobileNumber:
                            profileState.profile?.mobileNumber ?? 'N/A',
                        profileImageUrl: profileState.profile?.profileImageUrl,
                        onEditTap: () => context.push('/profile/edit'),
                      ),
                      AppSpacing.h24,
                      ProfileMenuItem(
                        imagePath: 'assets/svgs/profile/cupcake.png',
                        title: 'Order history',
                        titleFontSize: 14.sp,
                        titleFontWeight: FontWeight.w500,
                        onTap: () => context.push('/orders'),
                      ),
                      AppSpacing.h24,
                      const ProfileSectionHeader(title: 'Account settings'),
                      AppSpacing.h12,
                      ProfileMenuItem(
                        imagePath: 'assets/svgs/profile/settings.png',
                        title: 'Delivery Address',
                        titleFontSize: 14.sp,
                        titleFontWeight: FontWeight.w500,
                        onTap: () => context.push('/address-list'),
                      ),
                      AppSpacing.h24,
                      const ProfileSectionHeader(title: 'Support'),
                      AppSpacing.h12,
                      ProfileMenuItem(
                        imagePath: 'assets/svgs/profile/contact.png',
                        title: 'Contact Us',
                        titleFontSize: 14.sp,
                        titleFontWeight: FontWeight.w500,
                        onTap: () => context.push('/profile/contact'),
                      ),
                      AppSpacing.h12,
                      ProfileMenuItem(
                        imagePath: 'assets/svgs/profile/contact.png',
                        title: 'Log out',
                        titleFontSize: 14.sp,
                        titleFontWeight: FontWeight.w500,
                        showChevron: false,
                        onTap: () => _handleLogout(context),
                      ),
                      AppSpacing.h32,
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 280.w,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                'Are you logging out?',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                textAlign: TextAlign.center,
              ),
              Divider(color: AppColors.loaderGreen, thickness: 2.w),
              // Cancel button
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                  ),
                ),
              ),
              const Divider(color: AppColors.grey),
              // Log out button
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
                child: Text(
                  'Log out',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      // Clear profile data
      await ref.read(profileControllerProvider.notifier).logout();
      // Clear auth state (this updates the router's auth check)
      await ref.read(authProvider.notifier).logout();
      // Navigate to OTP screen
      if (context.mounted) {
        context.go('/otp');
      }
    }
  }
}
