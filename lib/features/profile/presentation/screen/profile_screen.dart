import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/colors.dart';
import '../../../address/presentation/screens/address_list_screen.dart';
import '../../application/providers/profile_provider.dart';
import '../components/profile_header.dart';
import '../components/profile_menu_item.dart';
import '../components/profile_section_header.dart';
import 'profile_edit_screen.dart';

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
          icon: Icon(Icons.arrow_back, color: AppColors.black, size: 24.sp),
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
      body: profileState.isLoading && !profileState.hasData
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.green),
            )
          : profileState.isError && !profileState.hasData
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        profileState.errorMessage ?? 'Something went wrong',
                        style:
                            TextStyle(fontSize: 14.sp, color: AppColors.grey),
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
                          style:
                              TextStyle(fontSize: 14.sp, color: AppColors.white),
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
                              border: Border.all(
                                color: Colors.orange.shade200,
                              ),
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
                          profileImageUrl:
                              profileState.profile?.profileImageUrl,
                          onEditTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const ProfileEditScreen(),
                              ),
                            );
                          },
                        ),
                        AppSpacing.h24,
                        ProfileMenuItem(
                          icon: Icons.shopping_bag_outlined,
                          title: 'Order history',
                          onTap: () {
                            // Navigate to order history screen
                          },
                        ),
                        AppSpacing.h24,
                        const ProfileSectionHeader(title: 'Account settings'),
                        AppSpacing.h12,
                        ProfileMenuItem(
                          icon: Icons.location_on_outlined,
                          title: 'Delivery Address',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const AddressListScreen(),
                              ),
                            );
                          },
                        ),
                        AppSpacing.h12,
                        ProfileMenuItem(
                          icon: Icons.payment_outlined,
                          title: 'Payment Methods',
                          onTap: () {
                            // Navigate to payment methods screen
                          },
                        ),
                        AppSpacing.h24,
                        const ProfileSectionHeader(title: 'Support'),
                        AppSpacing.h12,
                        ProfileMenuItem(
                          icon: Icons.headset_mic_outlined,
                          title: 'Contact Us',
                          onTap: () {
                            // Navigate to contact us screen
                          },
                        ),
                        AppSpacing.h12,
                        ProfileMenuItem(
                          icon: Icons.logout_outlined,
                          title: 'Log out',
                          showChevron: false,
                          onTap: () => _handleLogout(context),
                        ),
                        AppSpacing.h32,
                      ],
                    ),
                  ),
                ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Log out',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 14.sp, color: AppColors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Log out',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(profileControllerProvider.notifier).logout();
      // Navigate to login screen
      // Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}
