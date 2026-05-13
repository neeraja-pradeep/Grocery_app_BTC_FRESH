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
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final postalCodeController = TextEditingController();
  final countryController = TextEditingController();

  AddressType selectedType = AddressType.home;

  // 5-decimal-rounded strings (auth provider expects strings on the wire).
  String? _selectedLatitude;
  String? _selectedLongitude;
  String? _selectedAddressLabel;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    houseController.dispose();
    areaController.dispose();
    cityController.dispose();
    stateController.dispose();
    postalCodeController.dispose();
    countryController.dispose();
    super.dispose();
  }

  void _applySelectedLocation(SelectedLocation selected) {
    _selectedLatitude = selected.latitude.toStringAsFixed(5);
    _selectedLongitude = selected.longitude.toStringAsFixed(5);
    _selectedAddressLabel = selected.address;

    if (selected.city != null && selected.city!.isNotEmpty) {
      cityController.text = selected.city!;
    }
    if (selected.state != null && selected.state!.isNotEmpty) {
      stateController.text = selected.state!;
    }
    if (selected.postalCode != null && selected.postalCode!.isNotEmpty) {
      postalCodeController.text = selected.postalCode!;
    }
    if (selected.country != null && selected.country!.isNotEmpty) {
      countryController.text = selected.country!;
    }

    if (selected.address != null && selected.address!.isNotEmpty) {
      final parts = selected.address!
          .split(',')
          .map((e) => e.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (houseController.text.isEmpty && parts.isNotEmpty) {
        houseController.text = parts.first;
      }
      if (areaController.text.isEmpty && parts.length > 1) {
        areaController.text = parts.sublist(1).join(', ');
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

                // CITY
                AddressField(hint: 'City', controller: cityController),

                SizedBox(height: 30.h),

                // STATE
                AddressField(hint: 'State', controller: stateController),

                SizedBox(height: 30.h),

                // POSTAL + COUNTRY
                Row(
                  children: [
                    Expanded(
                      child: AddressField(
                        hint: 'Postal Code',
                        controller: postalCodeController,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: AddressField(
                        hint: 'Country',
                        controller: countryController,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24.h),

                // Pick on map — captures precise lat/lng and pre-fills the
                // city/state/postal/country fields above when blank.
                SizedBox(
                  width: double.infinity,
                  height: 44.h,
                  child: OutlinedButton.icon(
                    onPressed: _pickOnMap,
                    icon: Icon(
                      Icons.map_outlined,
                      color: AppColors.titleColor,
                      size: 18.sp,
                    ),
                    label: Text(
                      _selectedLatitude == null
                          ? 'Pick exact location on map'
                          : 'Update location on map',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.titleColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.titleColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                ),

                if (_selectedAddressLabel != null) ...[
                  SizedBox(height: 8.h),
                  Text(
                    'Pinned: $_selectedAddressLabel',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.titleColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                SizedBox(height: 24.h),

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

    ref
        .read(addressEntryProvider.notifier)
        .saveAddress(
          firstName: widget.user.firstName,
          lastName: widget.user.lastName,
          streetAddress: house,
          streetAddress2: area,
          addressType: selectedType,
          latitude: _selectedLatitude,
          longitude: _selectedLongitude,
          city: _trimmedOrNull(cityController),
          state: _trimmedOrNull(stateController),
          postalCode: _trimmedOrNull(postalCodeController),
          country: _trimmedOrNull(countryController),
        );
  }

  void _showError(String msg) {
    AppSnackbar.error(context, msg);
  }
}
