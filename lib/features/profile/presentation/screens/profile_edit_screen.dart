import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/button_styles.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/widgets/app_text.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing user data
    _fullNameController.text = '';
    _mobileController.text = '';
    _locationController.text = '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    // Save profile logic
    Navigator.pop(context);
  }

  void _deleteAccount() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: TextStyle(color: AppColors.loaderGreen, fontSize: 14.sp),
        ),
        content: Text(
          'Are you sure you want to delete your account? This action is permanent and cannot be undone.',
          style: TextStyle(fontSize: 13.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.loaderGreen),
            ),
          ),
          TextButton(
            onPressed: () {
              // Delete account logic
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

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
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  SizedBox(height: 16.h),

                  // Profile Header with Edit Avatar
                  Padding(
                    padding: EdgeInsets.only(left: 20.w, right: 20.w),
                    child: _buildProfileHeader(),
                  ),

                  SizedBox(height: 32.h),

                  // Full Name Field
                  Padding(
                    padding: EdgeInsets.only(left: 20.w, right: 20.w),
                    child: AppText(
                      text: 'Full name',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.lightGrey,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.only(left: 20.w, right: 20.w),
                    child: _buildTextField(
                      controller: _fullNameController,
                      hintText: 'name',
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Mobile Number Field
                  Padding(
                    padding: EdgeInsets.only(left: 20.w, right: 20.w),
                    child: AppText(
                      text: 'Mobile Number',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.lightGrey,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.only(left: 20.w, right: 20.w),
                    child: _buildTextField(
                      controller: _mobileController,
                      hintText: '0202020202',
                      keyboardType: TextInputType.phone,
                    ),
                  ),

                  SizedBox(height: 24.h),

                  // Location Field
                  Padding(
                    padding: EdgeInsets.only(left: 20.w, right: 20.w),
                    child: AppText(
                      text: 'Location',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.lightGrey,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.only(left: 20.w, right: 20.w),
                    child: _buildTextField(
                      controller: _locationController,
                      hintText: '',
                      maxLines: 4,
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Save Button
                  Padding(
                    padding: EdgeInsets.only(left: 20.w, right: 20.w),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ButtonStyles.lightgreenButton,
                        child: AppText(
                          text: 'Save',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.loaderGreen,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 32.h),

                  // Delete Account Button
                  Padding(
                    padding: EdgeInsets.only(left: 20.w, right: 20.w),
                    child: GestureDetector(
                      onTap: _deleteAccount,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.field,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: AppText(
                          text: 'Delete Account',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Delete Account Warning Text
                  Padding(
                    padding: EdgeInsets.only(left: 20.w, right: 20.w),
                    child: AppText(
                      text:
                          'Deleting your account is permanent and cannot be undone.',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.lightGrey,
                      maxLines: 2,
                    ),
                  ),

                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Row(
      children: [
        // Profile Avatar with Edit Icon
        Stack(
          children: [
            Container(
              width: 70.w,
              height: 70.h,
              decoration: const BoxDecoration(
                color: AppColors.field,
                shape: BoxShape.circle,
              ),
            ),
            // Edit Icon Overlay
            Positioned(
              bottom: 0,
              left: 45,
              child: Image.asset(
                "assets/svgs/profile/edit.png",
                height: 20.h,
                width: 20.w,
              ),
            ),
          ],
        ),

        SizedBox(width: 16.w),

        // Name and Phone
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              text: 'Rohith KG',
              fontSize: 18.sp,
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
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14.sp,
          color: AppColors.darkGrey,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14.sp,
            color: AppColors.lightGrey,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
