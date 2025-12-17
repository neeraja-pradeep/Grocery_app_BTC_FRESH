import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../app/theme/button_styles.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/location/location_provider.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../home/presentation/components/location_selection_screen.dart';
import '../../application/providers/address_providers.dart';
import '../../domain/entities/address.dart';

/// Address Screen for creating or editing addresses
/// Supports both create and edit modes based on whether address parameter is provided
class AddressScreen extends ConsumerStatefulWidget {
  const AddressScreen({super.key, this.address});

  /// If provided, screen will be in edit mode. Otherwise, create mode.
  final Address? address;

  @override
  ConsumerState<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends ConsumerState<AddressScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();

  String _selectedAddressType = 'home';
  bool _isSaving = false;

  // Location selection state
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedLocationAddress;

  @override
  void initState() {
    super.initState();
    // If editing, populate fields with existing data
    if (widget.address != null) {
      final address = widget.address!;
      _firstNameController.text = address.firstName;
      _lastNameController.text = address.lastName;
      _houseController.text = address.streetAddress1;
      _apartmentController.text = address.streetAddress2 ?? '';
      _selectedAddressType = address.addressType;

      // Load existing coordinates if available
      if (address.latitude != null && address.longitude != null) {
        _selectedLatitude = double.tryParse(address.latitude.toString());
        _selectedLongitude = double.tryParse(address.longitude.toString());
      }
    } else {
      // For new addresses, auto-load current location
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadCurrentLocation();
      });
    }
  }

  /// Load current location automatically for new addresses
  Future<void> _loadCurrentLocation() async {
    final locationState = ref.read(locationProvider);

    locationState.mapOrNull(
      loaded: (state) {
        setState(() {
          _selectedLatitude = state.location.latitude;
          _selectedLongitude = state.location.longitude;
        });
      },
    );
  }

  /// Open location selection screen
  Future<void> _selectLocation() async {
    // Get initial position (current location or existing coordinates)
    LatLng? initialPosition;

    if (_selectedLatitude != null && _selectedLongitude != null) {
      // Use previously selected location
      initialPosition = LatLng(_selectedLatitude!, _selectedLongitude!);
    } else {
      // Use current location if available
      final locationState = ref.read(locationProvider);
      locationState.mapOrNull(
        loaded: (state) {
          initialPosition = LatLng(
            state.location.latitude,
            state.location.longitude,
          );
        },
      );
    }

    // Navigate to location selection screen
    final selectedLocation = await Navigator.push<SelectedLocation>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LocationSelectionScreen(initialLocation: initialPosition),
      ),
    );

    // Update state with selected location
    if (selectedLocation != null && mounted) {
      setState(() {
        _selectedLatitude = selectedLocation.latitude;
        _selectedLongitude = selectedLocation.longitude;
        _selectedLocationAddress = selectedLocation.address;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _houseController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

  bool get _isEditMode => widget.address != null;

  Future<void> _saveAddress() async {
    // Validate fields
    if (_firstNameController.text.isEmpty || _houseController.text.isEmpty) {
      AppSnackbar.info(context, 'Please fill in all required fields');
      return;
    }

    // Backend requires last_name to not be blank, use "." as default if empty
    final lastName = _lastNameController.text.trim().isEmpty
        ? '.'
        : _lastNameController.text.trim();

    setState(() => _isSaving = true);

    try {
      // Round coordinates to 6 decimal places (max_digits=9, decimal_places=6)
      // This prevents "Ensure that there are no more than 9 digits in total" error
      final latitude = _selectedLatitude != null
          ? double.parse(_selectedLatitude!.toStringAsFixed(6))
          : null;
      final longitude = _selectedLongitude != null
          ? double.parse(_selectedLongitude!.toStringAsFixed(6))
          : null;

      if (_isEditMode) {
        // Update existing address
        await ref
            .read(addressControllerProvider.notifier)
            .updateAddress(
              id: widget.address!.id,
              firstName: _firstNameController.text.trim(),
              lastName: lastName,
              streetAddress1: _houseController.text.trim(),
              streetAddress2: _apartmentController.text.trim().isEmpty
                  ? null
                  : _apartmentController.text.trim(),
              latitude: latitude,
              longitude: longitude,
              addressType: _selectedAddressType,
            );
      } else {
        // Create new address
        await ref
            .read(addressControllerProvider.notifier)
            .createAddress(
              firstName: _firstNameController.text.trim(),
              lastName: lastName,
              streetAddress1: _houseController.text.trim(),
              streetAddress2: _apartmentController.text.trim().isEmpty
                  ? null
                  : _apartmentController.text.trim(),
              latitude: latitude,
              longitude: longitude,
              addressType: _selectedAddressType,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.success(
          context,
          _isEditMode
              ? 'Address updated successfully'
              : 'Address saved successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Unable to save address');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteAddress() async {
    if (!_isEditMode) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to delete this address?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(addressControllerProvider.notifier)
          .deleteAddress(widget.address!.id);

      if (mounted) {
        Navigator.pop(context);
        AppSnackbar.success(context, 'Address deleted successfully');
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Unable to delete address');
      }
    }
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
        title: AppText(
          text: _isEditMode ? 'Edit Address' : 'Add New Address',
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        actions: _isEditMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.loaderGreen),
                  onPressed: _deleteAddress,
                ),
              ]
            : null,
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
                      child: AppText(
                        text:
                            'A Detailed address will help our delivery partner reach your doorstep easily',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.green100,
                        maxLines: 3,
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // First Name
                    TextField(
                      controller: _firstNameController,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12.sp),
                      decoration: InputDecoration(
                        labelText: 'First Name *',
                        labelStyle: TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: 12.sp,
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

                    // Last Name
                    TextField(
                      controller: _lastNameController,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12.sp),
                      decoration: InputDecoration(
                        labelText: 'Last Name *',
                        labelStyle: TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: 12.sp,
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

                    // House / Flat / Block No.
                    TextField(
                      controller: _houseController,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12.sp),
                      decoration: InputDecoration(
                        labelText: 'House / Flat / Block No.',
                        labelStyle: TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: 12.sp,
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
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12.sp),
                      decoration: InputDecoration(
                        labelText: 'Apartment / Road / Area ( Recommended )',
                        labelStyle: TextStyle(
                          color: AppColors.lightGrey,
                          fontSize: 12.sp,
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

                    // Location Selection Section
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: AppColors.green10,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.green.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: AppColors.green100,
                                size: 20.sp,
                              ),
                              SizedBox(width: 8.w),
                              AppText(
                                text: 'Delivery Location',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.black,
                              ),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          if (_selectedLatitude != null &&
                              _selectedLongitude != null)
                            Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.green100,
                                    size: 18.sp,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          text: 'Location Selected',
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.green100,
                                        ),
                                        SizedBox(height: 4.h),
                                        if (_selectedLocationAddress != null)
                                          AppText(
                                            text: _selectedLocationAddress!,
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.lightGrey,
                                            maxLines: 2,
                                          )
                                        else
                                          AppText(
                                            text:
                                                'Lat: ${_selectedLatitude!.toStringAsFixed(6)}, Lng: ${_selectedLongitude!.toStringAsFixed(6)}',
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w400,
                                            color: AppColors.lightGrey,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            AppText(
                              text:
                                  'Select your location on map for accurate delivery',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: AppColors.green100,
                              maxLines: 2,
                            ),
                          SizedBox(height: 12.h),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _selectLocation,
                              icon: Icon(
                                Icons.map,
                                size: 18.sp,
                                color: AppColors.green100,
                              ),
                              label: AppText(
                                text: _selectedLatitude != null
                                    ? 'Change Location'
                                    : 'Select on Map',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.green100,
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                                side: const BorderSide(
                                  color: AppColors.green100,
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32.h),

                    // Save As Label
                    AppText(
                      text: 'Save As',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w400,
                      color: AppColors.lightGrey,
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
                        onPressed: _isSaving ? null : _saveAddress,
                        style: ButtonStyles.greenButton,
                        child: _isSaving
                            ? SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : AppText(
                                text: 'Done',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
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
    final value = label.toLowerCase();
    final isSelected = _selectedAddressType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAddressType = value;
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
            AppText(
              text: label,
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: isSelected ? AppColors.black : AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
