import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/button_styles.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../auth/application/states/auth_state.dart';
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
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  String _selectedAddressType = 'home';
  bool _isSaving = false;

  // lat/lng captured from the map picker — kept as double to match the cart
  // provider's createAddress/updateAddress signature.
  double? _selectedLatitude;
  double? _selectedLongitude;
  String? _selectedAddressLabel;

  @override
  void initState() {
    super.initState();
    // If editing, populate fields with existing data
    if (widget.address != null) {
      final address = widget.address!;
      _houseController.text = address.streetAddress1;
      _apartmentController.text = address.streetAddress2 ?? '';
      _cityController.text = address.city ?? '';
      _stateController.text = address.state ?? '';
      _postalCodeController.text = address.postalCode ?? '';
      _countryController.text = address.country ?? '';
      _selectedAddressType = address.addressType;
      _selectedLatitude = address.latitude;
      _selectedLongitude = address.longitude;
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

  bool get _isEditMode => widget.address != null;

  /// Apply a [SelectedLocation] (from the map picker) to the form: store
  /// lat/lng (rounded to 5 decimals) and prefill the structured fields when
  /// they're empty. Never clobber values the user has already typed.
  void _applySelectedLocation(SelectedLocation selected) {
    _selectedLatitude = double.parse(selected.latitude.toStringAsFixed(5));
    _selectedLongitude = double.parse(selected.longitude.toStringAsFixed(5));
    _selectedAddressLabel = selected.address;

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

  String? _trimmedOrNull(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  Future<void> _saveAddress() async {
    // Validate fields
    if (_houseController.text.isEmpty) {
      AppSnackbar.info(context, 'Please fill in all required fields');
      return;
    }

    // Auth guard — addresses require an authenticated user.
    final authState = ref.read(authProvider);
    if (authState is! Authenticated) {
      AppSnackbar.warning(context, 'Please log in to save an address');
      return;
    }

    final firstName = authState.user.firstName;
    final lastName = authState.user.lastName;

    setState(() => _isSaving = true);

    try {
      if (_isEditMode) {
        // Update existing address
        await ref
            .read(addressControllerProvider.notifier)
            .updateAddress(
              id: widget.address!.id,
              firstName: firstName,
              lastName: lastName,
              streetAddress1: _houseController.text.trim(),
              streetAddress2: _trimmedOrNull(_apartmentController),
              city: _trimmedOrNull(_cityController),
              state: _trimmedOrNull(_stateController),
              postalCode: _trimmedOrNull(_postalCodeController),
              country: _trimmedOrNull(_countryController),
              latitude: _selectedLatitude,
              longitude: _selectedLongitude,
              addressType: _selectedAddressType,
            );
      } else {
        // Create new address
        await ref
            .read(addressControllerProvider.notifier)
            .createAddress(
              firstName: firstName,
              lastName: lastName,
              streetAddress1: _houseController.text.trim(),
              streetAddress2: _trimmedOrNull(_apartmentController),
              city: _trimmedOrNull(_cityController),
              state: _trimmedOrNull(_stateController),
              postalCode: _trimmedOrNull(_postalCodeController),
              country: _trimmedOrNull(_countryController),
              latitude: _selectedLatitude,
              longitude: _selectedLongitude,
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

                    SizedBox(height: 24.h),

                    // City
                    TextField(
                      controller: _cityController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12.sp),
                      decoration: _underlineDecoration('City'),
                    ),

                    SizedBox(height: 24.h),

                    // State
                    TextField(
                      controller: _stateController,
                      textCapitalization: TextCapitalization.words,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12.sp),
                      decoration: _underlineDecoration('State'),
                    ),

                    SizedBox(height: 24.h),

                    // Postal Code + Country (same row)
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _postalCodeController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12.sp,
                            ),
                            decoration: _underlineDecoration('Postal Code'),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: TextField(
                            controller: _countryController,
                            textCapitalization:
                                TextCapitalization.characters,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12.sp,
                            ),
                            decoration: _underlineDecoration('Country'),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    // Pick on map — captures precise lat/lng and pre-fills
                    // city/state/postal/country fields above when blank.
                    SizedBox(
                      width: double.infinity,
                      height: 44.h,
                      child: OutlinedButton.icon(
                        onPressed: _pickOnMap,
                        icon: Icon(
                          Icons.map_outlined,
                          color: AppColors.green100,
                          size: 18.sp,
                        ),
                        label: AppText(
                          text: _selectedLatitude == null
                              ? 'Pick exact location on map'
                              : 'Update location on map',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.green100,
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.green100),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                    ),

                    if (_selectedAddressLabel != null) ...[
                      SizedBox(height: 8.h),
                      AppText(
                        text: 'Pinned: $_selectedAddressLabel',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.green100,
                        maxLines: 2,
                      ),
                    ],

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

  InputDecoration _underlineDecoration(String label) {
    return InputDecoration(
      labelText: label,
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
        borderSide: BorderSide(color: AppColors.green100, width: 2),
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
