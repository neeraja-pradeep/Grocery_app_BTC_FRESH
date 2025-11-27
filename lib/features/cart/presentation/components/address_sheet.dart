import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/button_styles.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/features/cart/presentation/screen/address_screen.dart';

class AddressSheet extends StatefulWidget {
  const AddressSheet({super.key});

  @override
  State<AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<AddressSheet> {
  String _selectedAddress = 'Home';

  final List<AddressModel> _addresses = [
    AddressModel(
      type: 'Home',
      address: 'Kovoor , medical college , Near Devagiri College , 645670',
    ),
    AddressModel(
      type: 'Work',
      address: 'Kovoor , medical college , Near Devagiri College , 645670',
    ),
    AddressModel(
      type: 'Other',
      address: 'Kovoor , medical college , Near Devagiri College , 645670',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 410.h,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.r),
          topRight: Radius.circular(24.r),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 10.h),

          Divider(
            indent: 140,
            endIndent: 140,
            thickness: 3,
            radius: BorderRadiusGeometry.circular(5.r),
            color: AppColors.lightGrey,
          ),
          // Header
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select an Address',
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1.h, color: AppColors.grey.withValues(alpha: 0.2)),

          // Address List
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              itemCount: _addresses.length,
              separatorBuilder: (context, index) => SizedBox(height: 16.h),
              itemBuilder: (context, index) {
                final address = _addresses[index];
                final isSelected = _selectedAddress == address.type;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAddress = address.type;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.grey.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Radio Button
                        Container(
                          width: 20.w,
                          height: 20.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.green100
                                  : AppColors.grey.withValues(alpha: 0.4),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? Center(
                                  child: Container(
                                    width: 10.w,
                                    height: 10.h,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.green100,
                                    ),
                                  ),
                                )
                              : null,
                        ),

                        SizedBox(width: 12.w),

                        // Address Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                address.type,
                                style: TextStyle(
                                  color: AppColors.black,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                address.address,
                                style: TextStyle(
                                  color: AppColors.lightGrey,
                                  fontSize: 12.sp,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),

                        // More Options Icon
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddressScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.more_vert),
                          iconSize: 20.h,
                          color: AppColors.black,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Add New Address Button
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to address screen or add new address
                  Navigator.pop(context);
                },
                style: ButtonStyles.greenButton,
                child: Text(
                  'Add New Address',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddressModel {
  final String type;
  final String address;

  AddressModel({required this.type, required this.address});
}
