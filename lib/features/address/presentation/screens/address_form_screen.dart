import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/colors.dart';
import '../../application/providers/address_provider.dart';
import '../../domain/entities/address.dart';

class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key, this.address});

  final Address? address;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _streetAddress1Controller;
  late TextEditingController _streetAddress2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;
  String _addressType = 'home';

  bool get isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    final address = widget.address;
    _firstNameController =
        TextEditingController(text: address?.firstName ?? '');
    _lastNameController = TextEditingController(text: address?.lastName ?? '');
    _streetAddress1Controller =
        TextEditingController(text: address?.streetAddress1 ?? '');
    _streetAddress2Controller =
        TextEditingController(text: address?.streetAddress2 ?? '');
    _cityController = TextEditingController(text: address?.city ?? '');
    _stateController = TextEditingController(text: address?.state ?? '');
    _postalCodeController =
        TextEditingController(text: address?.postalCode ?? '');
    _countryController = TextEditingController(text: address?.country ?? '');
    _addressType = address?.addressType ?? 'home';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _streetAddress1Controller.dispose();
    _streetAddress2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addressState = ref.watch(addressControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black, size: 24.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isEditing ? 'Edit Address' : 'Add New Address',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                label: 'First Name',
                controller: _firstNameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter first name';
                  }
                  return null;
                },
              ),
              AppSpacing.h16,
              _buildTextField(
                label: 'Last Name',
                controller: _lastNameController,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter last name';
                  }
                  return null;
                },
              ),
              AppSpacing.h16,
              _buildTextField(
                label: 'Street Address Line 1',
                controller: _streetAddress1Controller,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter street address';
                  }
                  return null;
                },
              ),
              AppSpacing.h16,
              _buildTextField(
                label: 'Street Address Line 2 (Optional)',
                controller: _streetAddress2Controller,
              ),
              AppSpacing.h16,
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'City',
                      controller: _cityController,
                    ),
                  ),
                  AppSpacing.w12,
                  Expanded(
                    child: _buildTextField(
                      label: 'State/Province',
                      controller: _stateController,
                    ),
                  ),
                ],
              ),
              AppSpacing.h16,
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      label: 'Postal Code',
                      controller: _postalCodeController,
                    ),
                  ),
                  AppSpacing.w12,
                  Expanded(
                    child: _buildTextField(
                      label: 'Country',
                      controller: _countryController,
                    ),
                  ),
                ],
              ),
              AppSpacing.h16,
              Text(
                'Address Type',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.black,
                ),
              ),
              AppSpacing.h8,
              Row(
                children: [
                  _buildAddressTypeChip('Home', 'home'),
                  AppSpacing.w8,
                  _buildAddressTypeChip('Work', 'work'),
                  AppSpacing.w8,
                  _buildAddressTypeChip('Other', 'other'),
                ],
              ),
              AppSpacing.h32,
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  onPressed: addressState.isCreating || addressState.isUpdating
                      ? null
                      : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green60,
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
                            color: AppColors.green100,
                          ),
                        )
                      : Text(
                          isEditing ? 'Update Address' : 'Save Address',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.green100,
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
        ),
        AppSpacing.h8,
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.green10,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: AppColors.green, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.r),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.w,
              vertical: 12.h,
            ),
          ),
        ),
      ],
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
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.green : AppColors.green10,
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: isSelected ? AppColors.green : AppColors.grey.withOpacity(0.3),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.white : AppColors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      if (isEditing) {
        await ref.read(addressControllerProvider.notifier).updateAddress(
              id: widget.address!.id,
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              streetAddress1: _streetAddress1Controller.text.trim(),
              streetAddress2: _streetAddress2Controller.text.trim().isEmpty
                  ? null
                  : _streetAddress2Controller.text.trim(),
              city: _cityController.text.trim().isEmpty
                  ? null
                  : _cityController.text.trim(),
              stateProvince: _stateController.text.trim().isEmpty
                  ? null
                  : _stateController.text.trim(),
              postalCode: _postalCodeController.text.trim().isEmpty
                  ? null
                  : _postalCodeController.text.trim(),
              country: _countryController.text.trim().isEmpty
                  ? null
                  : _countryController.text.trim(),
              addressType: _addressType,
            );
      } else {
        await ref.read(addressControllerProvider.notifier).createAddress(
              firstName: _firstNameController.text.trim(),
              lastName: _lastNameController.text.trim(),
              streetAddress1: _streetAddress1Controller.text.trim(),
              streetAddress2: _streetAddress2Controller.text.trim().isEmpty
                  ? null
                  : _streetAddress2Controller.text.trim(),
              city: _cityController.text.trim().isEmpty
                  ? null
                  : _cityController.text.trim(),
              stateProvince: _stateController.text.trim().isEmpty
                  ? null
                  : _stateController.text.trim(),
              postalCode: _postalCodeController.text.trim().isEmpty
                  ? null
                  : _postalCodeController.text.trim(),
              country: _countryController.text.trim().isEmpty
                  ? null
                  : _countryController.text.trim(),
              addressType: _addressType,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Address updated successfully'
                  : 'Address added successfully',
            ),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
