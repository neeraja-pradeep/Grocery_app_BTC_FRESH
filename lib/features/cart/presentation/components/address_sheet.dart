import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/button_styles.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../address/application/providers/address_provider.dart';
import '../../../home/application/providers/home_provider.dart';
import '../../../home/domain/entities/user_address.dart';
import '../../application/providers/address_providers.dart';
import '../../application/states/address_state.dart';
import '../screen/address_screen.dart';

/// Address Sheet with 30-second polling for real-time updates
/// Uses Riverpod to watch address list from API with automatic refresh
class AddressSheet extends ConsumerStatefulWidget {
  const AddressSheet({super.key});

  @override
  ConsumerState<AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends ConsumerState<AddressSheet> {
  int? _selectedAddressId;

  @override
  Widget build(BuildContext context) {
    // Watch address state from Riverpod provider (with 30-second polling)
    final addressState = ref.watch(addressControllerProvider);

    return Container(
      height: 390.h,
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

          const Divider(
            indent: 140,
            endIndent: 140,
            thickness: 3,
            color: AppColors.lightGrey,
          ),

          // Header with refresh indicator
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  text: 'Select an Address',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                // Show refresh indicator when polling
                if (addressState.isRefreshing)
                  SizedBox(
                    width: 16.w,
                    height: 16.h,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.green100,
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1.h, color: AppColors.grey.withValues(alpha: 0.2)),

          // Address List
          Expanded(child: _buildBody(addressState)),

          // Add New Address Button
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddressScreen(),
                    ),
                  );
                },
                style: ButtonStyles.greenButton,
                child: AppText(
                  text: 'Add New Address',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AddressState state) {
    // Handle loading state
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Handle error state
    if (state.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppText(
              text: 'Failed to load addresses',
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.grey,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                ref.read(addressControllerProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Handle empty state
    if (state.isEmpty || state.addresses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 40.sp,
              color: AppColors.grey,
            ),
            SizedBox(height: 16.h),
            AppText(
              text: 'No addresses found',
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.grey,
            ),
            SizedBox(height: 8.h),
            AppText(
              text: 'Add a new address to continue',
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.lightGrey,
            ),
          ],
        ),
      );
    }

    // Display addresses from API
    final addresses = state.addresses;
    final selectedAddress = state.selectedAddress;

    // Initialize selected address ID if not set
    if (_selectedAddressId == null && selectedAddress != null) {
      _selectedAddressId = selectedAddress.id;
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      itemCount: addresses.length,
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        final address = addresses[index];
        final isSelected = _selectedAddressId == address.id;

        return GestureDetector(
          onTap: () async {
            // Update local selection immediately for UI responsiveness
            setState(() {
              _selectedAddressId = address.id;
            });

            // Update the selected address in the provider state (local only)
            ref
                .read(addressControllerProvider.notifier)
                .setLocalSelectedAddress(address);

            // Convert to UserAddress and update home screen
            final userAddress = UserAddress(
              id: address.id,
              firstName: address.firstName,
              lastName: address.lastName,
              streetAddress1: address.streetAddress1,
              streetAddress2: address.streetAddress2,
              city: address.city ?? '',
              state: address.state ?? '',
              postalCode: address.postalCode ?? '',
              country: address.country ?? '',
              latitude: address.latitude?.toString(),
              longitude: address.longitude?.toString(),
              addressType: address.addressType,
              selected: true,
              createdAt: address.createdAt,
            );

            // Update home screen with selected address
            ref.read(homeProvider.notifier).updateAddressInState(userAddress);

            // Update profile address provider's local selection
            ref
                .read(profileAddressControllerProvider.notifier)
                .setLocalSelectedAddressId(address.id.toString());

            // Close the bottom sheet
            Navigator.pop(context);

            // Persist selection to backend (fire-and-forget)
            // This ensures the backend knows which address is selected for checkout
            ref
                .read(addressControllerProvider.notifier)
                .selectAddress(address.id);
          },
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected
                    ? AppColors.green100
                    : AppColors.grey.withValues(alpha: 0.2),
                width: isSelected ? 2 : 1,
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
                      Row(
                        children: [
                          AppText(
                            text: address.addressType.toUpperCase(),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                          SizedBox(width: 8.w),
                          AppText(
                            text: '(${address.fullName})',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w400,
                            color: AppColors.grey,
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      AppText(
                        text: address.formattedAddress,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.lightGrey,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                // More Options Menu (Edit/Delete)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddressScreen(address: address),
                        ),
                      );
                    } else if (value == 'delete') {
                      _handleDelete(context, address.id);
                    }
                  },
                  icon: Icon(
                    Icons.more_vert,
                    color: AppColors.black,
                    size: 18.h,
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18.sp),
                          SizedBox(width: 8.w),
                          const Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18.sp,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8.w),
                          const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleDelete(BuildContext context, int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete Address',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to delete this address?',
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 14.sp, color: AppColors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(addressControllerProvider.notifier).deleteAddress(id);

        // Sync profile address provider (just refresh, API delete already done)
        ref.read(profileAddressControllerProvider.notifier).fetchAddresses();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address deleted successfully'),
              backgroundColor: AppColors.green100,
            ),
          );
          // Close bottom sheet after delete
          Navigator.pop(context);
        }
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
