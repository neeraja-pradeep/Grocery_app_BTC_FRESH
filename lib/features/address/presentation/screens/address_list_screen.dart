import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/colors.dart';
import '../../application/providers/address_provider.dart';
import 'address_form_screen.dart';

class AddressListScreen extends ConsumerStatefulWidget {
  const AddressListScreen({super.key});

  @override
  ConsumerState<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends ConsumerState<AddressListScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(addressControllerProvider.notifier).fetchAddresses();
    });
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
          'Addresses',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: addressState.isLoading && !addressState.hasData
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.green),
            )
          : addressState.isError && !addressState.hasData
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    addressState.errorMessage ?? 'Something went wrong',
                    style: TextStyle(fontSize: 14.sp, color: AppColors.grey),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.h16,
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(addressControllerProvider.notifier)
                          .fetchAddresses();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(fontSize: 14.sp, color: AppColors.white),
                    ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: AppColors.green,
              onRefresh: () async {
                await ref
                    .read(addressControllerProvider.notifier)
                    .refreshAddresses();
              },
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(16.w),
                      children: [
                        // Stale warning at top
                        if (addressState.isStale)
                          Container(
                            padding: EdgeInsets.all(12.w),
                            margin: EdgeInsets.only(bottom: 16.h),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.orange.shade700,
                                  size: 20.sp,
                                ),
                                AppSpacing.w12,
                                Expanded(
                                  child: Text(
                                    'Showing offline data. Pull to refresh for latest updates.',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Address list
                        if (addressState.addresses.isEmpty)
                          Center(
                            child: Padding(
                              padding: EdgeInsets.only(top: 100.h),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.location_off_outlined,
                                    size: 64.sp,
                                    color: AppColors.grey,
                                  ),
                                  AppSpacing.h16,
                                  Text(
                                    'No addresses yet',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: AppColors.grey,
                                    ),
                                  ),
                                  AppSpacing.h8,
                                  Text(
                                    'Add your first address below',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...addressState.addresses.map(
                            (address) => Container(
                              margin: EdgeInsets.only(bottom: 12.h),
                              padding: EdgeInsets.all(16.w),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                  color: address.selected
                                      ? AppColors.green
                                      : AppColors.grey.withValues(alpha: 0.3),
                                  width: address.selected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Radio button
                                  Container(
                                    margin: EdgeInsets.only(top: 2.h),
                                    child: Icon(
                                      address.selected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: address.selected
                                          ? AppColors.green
                                          : AppColors.grey,
                                      size: 24.sp,
                                    ),
                                  ),
                                  AppSpacing.w12,
                                  // Address details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          address.addressTypeLabel,
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.black,
                                          ),
                                        ),
                                        AppSpacing.h4,
                                        Text(
                                          address.fullAddress,
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: AppColors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // 3-dot menu
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        final result =
                                            await Navigator.of(
                                              context,
                                            ).push<bool>(
                                              MaterialPageRoute<bool>(
                                                builder: (_) =>
                                                    AddressFormScreen(
                                                      address: address,
                                                    ),
                                              ),
                                            );
                                        if (result == true && mounted) {
                                          await ref
                                              .read(
                                                addressControllerProvider
                                                    .notifier,
                                              )
                                              .fetchAddresses();
                                        }
                                      } else if (value == 'delete') {
                                        _handleDelete(context, address.id);
                                      }
                                    },
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: AppColors.grey,
                                      size: 24.sp,
                                    ),
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.edit_outlined,
                                              size: 20.sp,
                                            ),
                                            AppSpacing.w8,
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
                                              size: 20.sp,
                                              color: Colors.red,
                                            ),
                                            AppSpacing.w8,
                                            const Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Add new addresses button at bottom
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.all(16.w),
                    child: ElevatedButton(
                      onPressed: () async {
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute<bool>(
                            builder: (_) => const AddressFormScreen(),
                          ),
                        );
                        if (result == true && mounted) {
                          await ref
                              .read(addressControllerProvider.notifier)
                              .fetchAddresses();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green10,
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Add new addresses',
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
    );
  }

  Future<void> _handleDelete(BuildContext context, String id) async {
    // Capture ScaffoldMessenger before async gap
    final messenger = ScaffoldMessenger.of(context);

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

    if (confirmed == true && mounted) {
      try {
        await ref.read(addressControllerProvider.notifier).deleteAddress(id);
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Address deleted successfully'),
              backgroundColor: AppColors.green,
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
