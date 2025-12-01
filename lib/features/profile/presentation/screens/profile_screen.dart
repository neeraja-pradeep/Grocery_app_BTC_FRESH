import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/widgets/app_text.dart';
import 'package:grocery_app/features/profile/presentation/screens/address_screen.dart';
import 'package:grocery_app/features/profile/presentation/screens/contact_screen.dart';
import 'package:grocery_app/features/profile/presentation/screens/order_screen.dart';
import 'package:grocery_app/features/profile/presentation/screens/profile_edit_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.black, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          text: 'My Profile',
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),

                SizedBox(height: 16.h),

                // Profile Header
                Padding(
                  padding: EdgeInsets.only(left: 20.w, right: 20.w),
                  child: _buildProfileHeader(context),
                ),

                SizedBox(height: 24.h),

                // Order History
                Padding(
                  padding: EdgeInsets.only(left: 20.w, right: 20.w),
                  child: _buildMenuItem(
                    url: "assets/svgs/profile/cupcake.png",
                    title: 'Order history',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OrderScreen(),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 24.h),

                // Account Settings Section
                Padding(
                  padding: EdgeInsets.only(left: 20.w, right: 20.w),
                  child: AppText(
                    text: 'Account settings',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),

                SizedBox(height: 16.h),

                // Delivery Address
                Padding(
                  padding: EdgeInsets.only(left: 20.w, right: 20.w),
                  child: _buildMenuItem(
                    url: "assets/svgs/profile/settings.png",
                    title: 'Delivery Address',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileAddressScreen(),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 24.h),

                // Support Section
                Padding(
                  padding: EdgeInsets.only(left: 20.w, right: 20.w),
                  child: AppText(
                    text: 'Support',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                  ),
                ),

                SizedBox(height: 16.h),

                // Contact Us
                Padding(
                  padding: EdgeInsets.only(left: 20.w, right: 20.w),
                  child: _buildMenuItem(
                    url: "assets/svgs/profile/contact.png",
                    title: 'Contact Us',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ContactScreen(),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 16.h),

                // Log out
                Padding(
                  padding: EdgeInsets.only(left: 20.w, right: 20.w),
                  child: _buildMenuItem(
                    url: "assets/svgs/profile/contact.png",
                    title: 'Log out',
                    showArrow: false,
                    onTap: () {
                      _showLogoutDialog(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Row(
      children: [
        // Profile Avatar
        Container(
          width: 60.w,
          height: 60.h,
          decoration: const BoxDecoration(
            color: AppColors.field,
            shape: BoxShape.circle,
          ),
        ),

        SizedBox(width: 16.w),

        // Name and Phone
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: 'Rohith KG',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
              SizedBox(height: 4.h),
              AppText(
                text: '6282655343',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.green,
              ),
            ],
          ),
        ),

        // Edit Icon
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProfileEditScreen(),
              ),
            );
          },
          icon: Image.asset(
            "assets/svgs/profile/edit.png",
            height: 20.h,
            width: 20.w,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required String url,
    required String title,
    required VoidCallback onTap,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: AppColors.field,
          borderRadius: BorderRadius.circular(4.r),
        ),
        child: Row(
          children: [
            // Icon
            Image.asset(url, height: 20.h, width: 20.w),

            SizedBox(width: 16.w),

            // Title
            Expanded(
              child: AppText(
                text: title,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.black,
              ),
            ),

            // Arrow
            if (showArrow)
              Icon(Icons.arrow_forward_ios, size: 16.sp, color: AppColors.grey),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Padding(
              padding: EdgeInsets.all(20.w),
              child: AppText(
                text: 'Are you logging out?',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.loaderGreen,
              ),
            ),

            const Divider(height: 1, color: AppColors.loaderGreen),

            // Cancel Button
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Center(
                  child: AppText(
                    text: 'Cancel',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                  ),
                ),
              ),
            ),

            const Divider(height: 1),

            // Log out Button
            InkWell(
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement actual logout logic
                // Clear user session, navigate to login screen, etc.
              },
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16.r),
                bottomRight: Radius.circular(16.r),
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Center(
                  child: AppText(
                    text: 'Log out',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
