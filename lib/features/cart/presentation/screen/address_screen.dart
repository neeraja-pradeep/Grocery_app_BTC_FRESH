import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/button_styles.dart';
import 'package:grocery_app/app/theme/colors.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();

  String _selectedAddressType = 'Home';

  @override
  void dispose() {
    _houseController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.green10,
      appBar: AppBar(
        backgroundColor: AppColors.green10,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.black, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit address',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 16.h),

                    // Info Banner
                    Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.green10,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        'A Detailed address will help our delivery partner reach your doorstep easily',
                        style: TextStyle(
                          color: AppColors.green100,
                          fontSize: 12.sp,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // House / Flat / Block No.
                    TextField(
                      controller: _houseController,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
                      decoration: InputDecoration(
                        labelText: 'House / Flat / Block No.',
                        labelStyle: TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: 14.sp,
                          fontFamily: 'Poppins',
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.grey.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.green100,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Apartment / Road / Area
                    TextField(
                      controller: _apartmentController,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
                      decoration: InputDecoration(
                        labelText: 'Apartment / Road / Area ( Recommended )',
                        labelStyle: TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: 14.sp,
                          fontFamily: 'Poppins',
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.grey.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.green100,
                            width: 2,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Save As Label
                    Text(
                      'Save As',
                      style: TextStyle(
                        color: AppColors.lightGrey,
                        fontSize: 14.sp,
                        fontFamily: 'Poppins',
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // Address Type Chips
                    Row(
                      children: [
                        _buildAddressTypeChip('Home', Icons.home),
                        SizedBox(width: 12.w),
                        _buildAddressTypeChip('Work', Icons.work_outline),
                        SizedBox(width: 12.w),
                        _buildAddressTypeChip(
                          'Other',
                          Icons.location_on_outlined,
                        ),
                      ],
                    ),

                    SizedBox(height: 32.h),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Save address and navigate back
                          Navigator.pop(context);
                        },
                        style: ButtonStyles.greenButton,
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: AppColors.green100,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
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
        ],
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
          color: AppColors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16.sp,
              color: isSelected ? AppColors.black : AppColors.grey,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.black : AppColors.grey,
                fontSize: 14.sp,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
