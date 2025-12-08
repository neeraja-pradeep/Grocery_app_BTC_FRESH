import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';

/// Address Screen - Collect user address after sign up
class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final _houseController = TextEditingController();
  final _apartmentController = TextEditingController();
  String _selectedAddressType = 'Home';

  @override
  void dispose() {
    _houseController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

  void _handleDone() {
    final house = _houseController.text.trim();

    if (house.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter house/flat/block number')),
      );
      return;
    }

    // TODO: Save address via API
    // Navigate to home/main screen
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.home,
      (route) => false,
    );
  }

  void _handleSkip() {
    // Skip address and go to home
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.home,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 60.h),

                // App logo - centered
                Center(
                  child: Image.asset(
                    'assets/title.png',
                    height: 78.h,
                    width: 128.w,
                    fit: BoxFit.contain,
                  ),
                ),

                SizedBox(height: 32.h),

                // Address heading with location icon
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: AppColors.green100,
                      size: 28.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Address',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green100,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),

                // Info box
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.green60.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.green100.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'A Detailed address will help our delivery partner reach your doorstep easily',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.green100,
                    ),
                  ),
                ),

                SizedBox(height: 32.h),

                // House / Flat / Block No. field
                TextField(
                  controller: _houseController,
                  decoration: InputDecoration(
                    hintText: 'House / Flat / Block No.',
                    hintStyle: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.grey,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.green100),
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Apartment / Road / Area field
                TextField(
                  controller: _apartmentController,
                  decoration: InputDecoration(
                    hintText: 'Apartment / Road / Area ( Recommended )',
                    hintStyle: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.grey,
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(
                        color: AppColors.grey.withValues(alpha: 0.3),
                      ),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.green100),
                    ),
                  ),
                ),

                SizedBox(height: 24.h),

                // Save As label
                Text(
                  'Save As',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.grey,
                  ),
                ),

                SizedBox(height: 12.h),

                // Address type chips
                Row(
                  children: [
                    _buildAddressTypeChip('Home', Icons.home_outlined),
                    SizedBox(width: 12.w),
                    _buildAddressTypeChip('Work', Icons.work_outline),
                    SizedBox(width: 12.w),
                    _buildAddressTypeChip('Other', Icons.location_on_outlined),
                  ],
                ),

                SizedBox(height: 48.h),

                // Done button
                SizedBox(
                  width: double.infinity,
                  height: 50.h,
                  child: ElevatedButton(
                    onPressed: _handleDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green60,
                      foregroundColor: AppColors.green100,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green100,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                // Skip link
                Center(
                  child: GestureDetector(
                    onTap: _handleSkip,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.green100,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.green100,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressTypeChip(String label, IconData icon) {
    final isSelected = _selectedAddressType == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAddressType = label;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.green100 : AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppColors.green100
                : AppColors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18.sp,
              color: isSelected ? AppColors.white : AppColors.grey,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.white : AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
