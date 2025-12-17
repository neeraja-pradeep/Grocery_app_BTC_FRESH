import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/utils/address_enum.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../application/providers/address_provider.dart';
import '../../application/states/address_states.dart';
import '../../domain/entities/user.dart';
import '../components/address_field.dart';
import '../components/address_tags.dart';
import '../components/address_tip.dart';

class AddressScreen extends ConsumerStatefulWidget {
  final UserEntity user;

  const AddressScreen({super.key, required this.user});

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  final houseController = TextEditingController();
  final areaController = TextEditingController();

  AddressType selectedType = AddressType.home;

  @override
  void dispose() {
    houseController.dispose();
    areaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addressState = ref.watch(addressEntryProvider);

    // Listen to state changes
    ref.listen<AddressState>(addressEntryProvider, (prev, next) {
      if (next is AddressSaved) {
        goToHome(context);
      }

      if (next is AddressSkipped) {
        goToHome(context);
      }

      if (next is AddressError) {
        _showError(next.failure.message);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 40.h),
                Center(child: Image.asset('assets/title.png', width: 110.w)),
                SizedBox(height: 20.h),

                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 25.sp,
                      color: AppColors.titleColor,
                    ),
                    Text(
                      'Address',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 28.sp,
                        color: AppColors.titleColor,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20.h),
                const AddressTip(),
                SizedBox(height: 20.h),

                // HOUSE NUMBER
                AddressField(
                  hint: 'House / Flat / Block No.',
                  controller: houseController,
                ),

                SizedBox(height: 40.h),

                // AREA
                AddressField(
                  hint: 'Apartment / Road / Area',
                  controller: areaController,
                ),

                SizedBox(height: 30.h),

                Text(
                  'Save As',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),

                SizedBox(height: 8.h),

                Row(
                  children: [
                    AddressTag(
                      label: 'Home',
                      icon: Icons.home,
                      isSelected: selectedType == AddressType.home,
                      onTap: () => setState(() {
                        selectedType = AddressType.home;
                      }),
                    ),
                    SizedBox(width: 10.w),
                    AddressTag(
                      label: 'Work',
                      icon: Icons.work,
                      isSelected: selectedType == AddressType.work,
                      onTap: () => setState(() {
                        selectedType = AddressType.work;
                      }),
                    ),
                    SizedBox(width: 10.w),
                    AddressTag(
                      label: 'Other',
                      icon: Icons.location_on,
                      isSelected: selectedType == AddressType.other,
                      onTap: () => setState(() {
                        selectedType = AddressType.other;
                      }),
                    ),
                  ],
                ),

                SizedBox(height: 40.h),

                // MAIN BUTTON
                GestureDetector(
                  onTap: () => _handleSave(addressState),
                  child: Container(
                    width: double.infinity,
                    height: 55.h,
                    decoration: BoxDecoration(
                      color: AppColors.lightGreen,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Center(
                      child: Text(
                        addressState is AddressSaving
                            ? 'Saving Address...'
                            : 'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                          color: AppColors.titleColor,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20.h),

                Center(
                  child: GestureDetector(
                    onTap: () {
                      ref.read(addressEntryProvider.notifier).skipAddress();
                    },
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontSize: 16.sp,
                        color: AppColors.titleColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSave(AddressState state) {
    final house = houseController.text.trim();
    final area = areaController.text.trim();

    if (house.isEmpty || area.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    final fullAddress = '$house, $area';

    ref
        .read(addressEntryProvider.notifier)
        .saveAddress(
          firstName: widget.user.firstName,
          lastName: widget.user.lastName,
          streetAddress: fullAddress,
          addressType: selectedType,
        );
  }

  void _showError(String msg) {
    AppSnackbar.error(context, msg);
  }
}
