import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/button_styles.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/features/cart/application/providers/address_providers.dart';
import 'package:grocery_app/features/cart/domain/entities/address.dart';

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
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _houseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (_isEditMode) {
        // Update existing address
        await ref
            .read(addressControllerProvider.notifier)
            .updateAddress(
              id: widget.address!.id,
              firstName: _firstNameController.text,
              lastName: _lastNameController.text,
              streetAddress1: _houseController.text,
              streetAddress2: _apartmentController.text.isEmpty
                  ? null
                  : _apartmentController.text,
              addressType: _selectedAddressType,
            );
      } else {
        // Create new address
        await ref
            .read(addressControllerProvider.notifier)
            .createAddress(
              firstName: _firstNameController.text,
              lastName: _lastNameController.text,
              streetAddress1: _houseController.text,
              streetAddress2: _apartmentController.text.isEmpty
                  ? null
                  : _apartmentController.text,
              addressType: _selectedAddressType,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Address updated successfully'
                  : 'Address added successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save address: $e')));
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Address deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to delete address: $e')));
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
        title: Text(
          _isEditMode ? 'Edit Address' : 'Add New Address',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
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

                    // First Name
                    TextField(
                      controller: _firstNameController,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
                      decoration: InputDecoration(
                        labelText: 'First Name *',
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

                    // Last Name
                    TextField(
                      controller: _lastNameController,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14.sp),
                      decoration: InputDecoration(
                        labelText: 'Last Name *',
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
                            : Text(
                                'Done',
                                style: TextStyle(
                                  color: AppColors.white,
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
