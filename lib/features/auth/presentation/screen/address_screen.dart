import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/utils/address_enum.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../home/presentation/components/location_selection_screen.dart';
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

  // Location data from map
  SelectedLocation? _selectedLocation;
  bool _hasLocationFromMap = false;

  @override
  void dispose() {
    houseController.dispose();
    areaController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<SelectedLocation>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const LocationSelectionScreen(returnLocationOnly: true),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLocation = result;
        _hasLocationFromMap = true;
        // Auto-fill address field with the address from map
        if (result.address != null && result.address!.isNotEmpty) {
          areaController.text = result.address!;
        }
      });
    }
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

                // CHOOSE FROM MAP BUTTON
                _buildMapPickerButton(),

                SizedBox(height: 20.h),

                // Location status indicator
                if (_hasLocationFromMap) _buildLocationStatus(),

                if (_hasLocationFromMap) SizedBox(height: 20.h),

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

  Widget _buildMapPickerButton() {
    return GestureDetector(
      onTap: _openMapPicker,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: _hasLocationFromMap
                ? AppColors.titleColor
                : Colors.grey.shade300,
            width: _hasLocationFromMap ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(
                Icons.my_location,
                color: AppColors.titleColor,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hasLocationFromMap
                        ? 'Location Selected'
                        : 'Choose from Map',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                      color: AppColors.titleColor,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _hasLocationFromMap
                        ? 'Tap to change location'
                        : 'Use current location or pick from map',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              _hasLocationFromMap
                  ? Icons.check_circle
                  : Icons.arrow_forward_ios,
              color: _hasLocationFromMap
                  ? AppColors.titleColor
                  : Colors.grey.shade400,
              size: _hasLocationFromMap ? 24.sp : 16.sp,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationStatus() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.lightGreen.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: AppColors.titleColor, size: 20.sp),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              _selectedLocation?.address ?? 'Location selected',
              style: TextStyle(fontSize: 13.sp, color: AppColors.titleColor),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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

    // Round coordinates to 6 decimal places for backend compatibility
    String? lat;
    String? lng;
    if (_selectedLocation != null) {
      lat = _selectedLocation!.latitude.toStringAsFixed(6);
      lng = _selectedLocation!.longitude.toStringAsFixed(6);
    }

    ref
        .read(addressEntryProvider.notifier)
        .saveAddress(
          firstName: widget.user.firstName,
          lastName: widget.user.lastName,
          streetAddress: house,
          streetAddress2: area,
          addressType: selectedType,
          latitude: lat,
          longitude: lng,
          city: _selectedLocation?.city,
          state: _selectedLocation?.state,
          postalCode: _selectedLocation?.postalCode,
        );
  }

  void _showError(String msg) {
    AppSnackbar.error(context, msg);
  }
}
