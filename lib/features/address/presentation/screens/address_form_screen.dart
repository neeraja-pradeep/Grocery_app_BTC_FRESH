import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/location/location_service.dart';
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
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;
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
    _cityController = TextEditingController(text: address?.city ?? '');
    _stateController = TextEditingController(text: address?.state ?? '');
    _postalCodeController = TextEditingController(
      text: address?.postalCode ?? '',
    );
    _countryController = TextEditingController(text: address?.country ?? '');
    _addressType = address?.addressType ?? 'home';

    // If location was selected from map, store the coordinates and prefill
    // city/state/postal_code/country from the map's reverse-geocoded data.
    if (selectedLocation != null) {
      _applySelectedLocation(selectedLocation);
    }
  }

  /// Apply a [SelectedLocation] (from the map picker) to the form: store
  /// lat/lng, prefill the structured city/state/postal/country fields, and
  /// seed house/apartment from the address string when those text fields
  /// are still empty.
  void _applySelectedLocation(SelectedLocation selected) {
    _selectedLatitude = selected.latitude.toStringAsFixed(5);
    _selectedLongitude = selected.longitude.toStringAsFixed(5);
    _selectedAddress = selected.address;

    // Only overwrite the structured fields when the picker actually provided
    // a value — preserves anything the user has already typed.
    if (selected.city != null && selected.city!.isNotEmpty) {
      _cityController.text = selected.city!;
    }
    if (selected.state != null && selected.state!.isNotEmpty) {
      _stateController.text = selected.state!;
    }
    if (selected.postalCode != null && selected.postalCode!.isNotEmpty) {
      _postalCodeController.text = selected.postalCode!;
    }
    if (selected.country != null && selected.country!.isNotEmpty) {
      _countryController.text = selected.country!;
    }

    // Seed house/apartment from the picker's full address string only if
    // they're still empty — never clobber user-typed values.
    if (selected.address != null && selected.address!.isNotEmpty) {
      final parts = selected.address!
          .split(',')
          .map((e) => e.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (_houseController.text.isEmpty && parts.isNotEmpty) {
        _houseController.text = parts.first;
      }
      if (_apartmentController.text.isEmpty && parts.length > 1) {
        _apartmentController.text = parts.sublist(1).join(', ');
      }
    }
  }

  Future<void> _pickOnMap() async {
    final result = await Navigator.of(context).push<SelectedLocation>(
      MaterialPageRoute<SelectedLocation>(
        builder: (_) => const LocationSelectionScreen(returnLocationOnly: true),
      ),
    );
    if (result != null && mounted) {
      setState(() => _applySelectedLocation(result));
    }
  }

  @override
  void dispose() {
    _houseController.dispose();
    _apartmentController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addressState = ref.watch(profileAddressControllerProvider);

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
              AppSpacing.h24,

              // City
              TextFormField(
                controller: _cityController,
                textCapitalization: TextCapitalization.words,
                decoration: _underlineDecoration('City'),
              ),
              AppSpacing.h24,

              // State
              TextFormField(
                controller: _stateController,
                textCapitalization: TextCapitalization.words,
                decoration: _underlineDecoration('State'),
              ),
              AppSpacing.h24,

              // Postal Code
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _postalCodeController,
                      keyboardType: TextInputType.number,
                      decoration: _underlineDecoration('Postal Code'),
                    ),
                  ),
                  AppSpacing.w16,
                  Expanded(
                    child: TextFormField(
                      controller: _countryController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _underlineDecoration('Country'),
                    ),
                  ),
                ],
              ),
              AppSpacing.h24,

              // Pick on map — captures precise lat/lng and pre-fills the
              // city/state/postal/country fields above.
              SizedBox(
                width: double.infinity,
                height: 44.h,
                child: OutlinedButton.icon(
                  onPressed: _pickOnMap,
                  icon: Icon(
                    Icons.map_outlined,
                    color: AppColors.green,
                    size: 18.sp,
                  ),
                  label: Text(
                    _selectedLatitude == null
                        ? 'Pick exact location on map'
                        : 'Update location on map',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.green,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
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

  InputDecoration _underlineDecoration(String label) {
    return InputDecoration(
      labelText: label,
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

    // If no location was selected from map, fall back to whatever the
    // location provider already has cached/loaded. We deliberately do NOT
    // trigger a force-fresh fetch here: that would block the Save action on
    // an OS permission popup and a 15-second GPS timeout, freezing the form.
    // The home screen's initialize() already hydrates the cache on launch,
    // so the loaded state is usually fresh enough.
    bool locationTimedOut = false;
    if (latitude == null || longitude == null) {
      final locationState = ref.read(locationProvider);
      locationState.mapOrNull(
        loaded: (state) {
          latitude = state.location.latitude.toStringAsFixed(5);
          longitude = state.location.longitude.toStringAsFixed(5);
        },
        error: (errorState) {
          locationTimedOut = errorState.failure is LocationTimeoutFailure;
          // LowAccuracy still exposes a reading via previousLocation — use it
          // rather than dropping the coordinates entirely.
          final fallback = errorState.previousLocation;
          if (fallback != null) {
            latitude = fallback.latitude.toStringAsFixed(5);
            longitude = fallback.longitude.toStringAsFixed(5);
          }
        },
      );
    }

    // Warn user when no coordinates are available so they know delivery
    // precision may be affected (coordinates are optional on the backend).
    if ((latitude == null || longitude == null) && mounted) {
      AppSnackbar.warning(
        context,
        locationTimedOut
            ? 'Location lookup timed out — saved without coordinates. Reopen this address and tap the map pin to retry.'
            : 'Location unavailable — address will be saved without coordinates.',
      );
    }

    String? trimmedOrNull(TextEditingController c) {
      final v = c.text.trim();
      return v.isEmpty ? null : v;
    }

    final cityValue = trimmedOrNull(_cityController);
    final stateValue = trimmedOrNull(_stateController);
    final postalCodeValue = trimmedOrNull(_postalCodeController);
    final countryValue = trimmedOrNull(_countryController);

    try {
      if (isEditing) {
        await ref
            .read(profileAddressControllerProvider.notifier)
            .updateAddress(
              id: widget.address!.id,
              firstName: firstName,
              lastName: lastName,
              streetAddress1: _houseController.text.trim(),
              streetAddress2: trimmedOrNull(_apartmentController),
              city: cityValue,
              stateProvince: stateValue,
              postalCode: postalCodeValue,
              country: countryValue,
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
              streetAddress2: trimmedOrNull(_apartmentController),
              city: cityValue,
              stateProvince: stateValue,
              postalCode: postalCodeValue,
              country: countryValue,
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
