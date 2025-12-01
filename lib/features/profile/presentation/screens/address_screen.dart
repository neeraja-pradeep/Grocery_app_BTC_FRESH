import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/button_styles.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/widgets/app_text.dart';
import 'package:grocery_app/features/cart/application/providers/address_providers.dart';
import 'package:grocery_app/features/cart/application/states/address_state.dart';
import 'package:grocery_app/features/cart/presentation/screen/address_screen.dart'
    as cart;

/// Address List Screen - Full page version of AddressSheet
/// Shows all saved addresses with ability to select, edit, or add new ones
/// Uses Riverpod to watch address list from API with automatic 30-second polling
class ProfileAddressScreen extends ConsumerStatefulWidget {
  const ProfileAddressScreen({super.key});

  @override
  ConsumerState<ProfileAddressScreen> createState() =>
      _ProfileAddressScreenState();
}

class _ProfileAddressScreenState extends ConsumerState<ProfileAddressScreen> {
  int? _selectedAddressId;

  @override
  Widget build(BuildContext context) {
    // Watch address state from Riverpod provider (with 30-second polling)
    final addressState = ref.watch(addressControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.black, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          text: 'Addresses',
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        actions: [
          // Show refresh indicator when polling
          if (addressState.isRefreshing)
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Center(
                child: SizedBox(
                  width: 16.w,
                  height: 16.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.green100,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          const Divider(),

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
                      builder: (context) => const cart.AddressScreen(),
                    ),
                  );
                },
                style: ButtonStyles.lightgreenButton,
                child: AppText(
                  text: 'Add new addresses',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.loaderGreen,
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green100),
      );
    }

    // Handle error state
    if (state.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: AppColors.grey),
            SizedBox(height: 16.h),
            AppText(
              text: 'Failed to load addresses',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.grey,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                ref.read(addressControllerProvider.notifier).refresh();
              },
              style: ButtonStyles.greenButton,
              child: AppText(
                text: 'Retry',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.white,
              ),
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
              size: 60.sp,
              color: AppColors.grey,
            ),
            SizedBox(height: 16.h),
            AppText(
              text: 'No addresses found',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
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
          onTap: () {
            // Update local selection
            setState(() {
              _selectedAddressId = address.id;
            });

            // Update the selected address in the provider state (local only)
            ref
                .read(addressControllerProvider.notifier)
                .setLocalSelectedAddress(address);
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
                      AppText(
                        text: address.addressType.toUpperCase(),
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                      SizedBox(height: 4.h),
                      AppText(
                        text: address.formattedAddress,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: AppColors.lightGrey,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),

                // More Options Icon
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            cart.AddressScreen(address: address),
                      ),
                    );
                  },
                  icon: const Icon(Icons.more_vert),
                  iconSize: 20.sp,
                  color: AppColors.black,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
