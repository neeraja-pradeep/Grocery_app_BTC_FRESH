import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../profile/application/providers/profile_provider.dart';
import '../../application/providers/address_provider.dart';
import '../../domain/entities/address.dart';
import '../../../home/presentation/components/location_selection_screen.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.address, this.selectedLocation});

  final Address? address;
  final SelectedLocation? selectedLocation;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _houseController;
  late TextEditingController _apartmentController;
  String _addressType = 'home';

  // Store selected location coordinates from map
  String? _selectedLatitude;
  String? _selectedLongitude;
  String? _selectedAddress;

  bool get isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    final selectedLocation = widget.selectedLocation;

    // Initialize form fields from existing address or empty
    _houseController = TextEditingController(
      text: address?.streetAddress1 ?? '',
    );
    _apartmentController = TextEditingController(
      text: address?.streetAddress2 ?? '',
    );
    _addressType = address?.addressType ?? 'home';

    // If location was selected from map, store the coordinates and address
    if (selectedLocation != null) {
      _selectedLatitude = selectedLocation.latitude.toStringAsFixed(6);
      _selectedLongitude = selectedLocation.longitude.toStringAsFixed(6);
      _selectedAddress = selectedLocation.address;

      // Split the selected address between both fields
      if (selectedLocation.address != null &&
          selectedLocation.address!.isNotEmpty) {
        final fullAddress = selectedLocation.address!;
        // Split by comma to get address parts
        final parts = fullAddress.split(',').map((e) => e.trim()).toList();

        if (parts.isNotEmpty) {
          // First part goes to house/flat field
          _houseController.text = parts.first;

          // Remaining parts go to apartment/road field
          if (parts.length > 1) {
            _apartmentController.text = parts.sublist(1).join(', ');
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _houseController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addressState = ref.watch(profileAddressControllerProvider);
    // Profile state watched for reactivity, not directly used
    ref.watch(profileControllerProvider);

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
        title: Row(
          children: [
            Icon(Icons.location_on, color: AppColors.green, size: 20.sp),
            AppSpacing.w8,
            Text(
              'Address',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Selected location banner (if available)
              if (_selectedAddress != null) ...[
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: AppColors.green,
                        size: 16.sp,
                      ),
                      AppSpacing.w8,
                      Expanded(
                        child: Text(
                          'Selected Location: $_selectedAddress',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.h16,
              ],

              // Info banner
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
                  style: TextStyle(fontSize: 12.sp, color: AppColors.green),
                ),
              ),
              AppSpacing.h24,

              // House / Flat / Block No.
              TextFormField(
                controller: _houseController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter house/flat/block number';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'House / Flat / Block No.',
                  labelStyle: TextStyle(fontSize: 14.sp, color: AppColors.grey),
                  filled: false,
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.grey),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.grey),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.green, width: 2),
                  ),
                  errorBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.red),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
              AppSpacing.h24,

              // Apartment / Road / Area (Recommended)
              TextFormField(
                controller: _apartmentController,
                decoration: InputDecoration(
                  labelText: 'Apartment / Road / Area ( Recommended )',
                  labelStyle: TextStyle(fontSize: 14.sp, color: AppColors.grey),
                  filled: false,
                  border: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.grey),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.grey),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.green, width: 2),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
              ),
              AppSpacing.h32,

              // Save As section
              Text(
                'Save As',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
              AppSpacing.h12,
              Row(
                children: [
                  _buildAddressTypeChip('Home', 'home'),
                  AppSpacing.w12,
                  _buildAddressTypeChip('Work', 'work'),
                  AppSpacing.w12,
                  _buildAddressTypeChip('Other', 'other'),
                ],
              ),
              AppSpacing.h48,

              // Done button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: addressState.isCreating || addressState.isUpdating
                      ? null
                      : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    elevation: 0,
                  ),
                  child: addressState.isCreating || addressState.isUpdating
                      ? SizedBox(
                          height: 20.h,
                          width: 20.w,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.green,
                          ),
                        )
                      : Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.green,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressTypeChip(String label, String value) {
    final isSelected = _addressType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _addressType = value;
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isSelected ? AppColors.green : AppColors.grey,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: isSelected ? AppColors.green : AppColors.grey,
                size: 20.sp,
              ),
              AppSpacing.w4,
              Text(
                label,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppColors.green : AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Get user's name from profile
    final profileState = ref.read(profileControllerProvider);
    final profile = profileState.profile;

    // Use profile name or default values
    String firstName = 'User';
    String lastName = '.'; // Backend requires non-blank last_name

    if (profile != null && profile.fullName.isNotEmpty) {
      final nameParts = profile.fullName.split(' ');
      firstName = nameParts.first;
      if (nameParts.length > 1) {
        lastName = nameParts.sublist(1).join(' ');
      }
    }

    // Get location coordinates - use selected location from map if available,
    // otherwise get current location from provider
    String? latitude = _selectedLatitude;
    String? longitude = _selectedLongitude;

    // If no location was selected from map, get current location
    if (latitude == null || longitude == null) {
      final locationState = ref.read(locationProvider);
      locationState.mapOrNull(
        loaded: (state) {
          // Round to 6 decimal places (max_digits=9, decimal_places=6)
          // Format: XXX.XXXXXX (3 digits before decimal, 6 after)
          latitude = state.location.latitude.toStringAsFixed(6);
          longitude = state.location.longitude.toStringAsFixed(6);
        },
      );
    }

    try {
      if (isEditing) {
        await ref
            .read(profileAddressControllerProvider.notifier)
            .updateAddress(
              id: widget.address!.id,
              firstName: firstName,
              lastName: lastName,
              streetAddress1: _houseController.text.trim(),
              streetAddress2: _apartmentController.text.trim().isEmpty
                  ? null
                  : _apartmentController.text.trim(),
              latitude: latitude,
              longitude: longitude,
              addressType: _addressType,
            );
      } else {
        await ref
            .read(profileAddressControllerProvider.notifier)
            .createAddress(
              firstName: firstName,
              lastName: lastName,
              streetAddress1: _houseController.text.trim(),
              streetAddress2: _apartmentController.text.trim().isEmpty
                  ? null
                  : _apartmentController.text.trim(),
              latitude: latitude,
              longitude: longitude,
              addressType: _addressType,
            );
      }

      if (mounted) {
        AppSnackbar.success(
          context,
          isEditing
              ? 'Address updated successfully'
              : 'Address added successfully',
        );
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        AppSnackbar.error(context, error.toString());
      }
    }
  }
}
