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
          'Delivery Address',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: AppColors.green, size: 24.sp),
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
          ),
        ],
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
              child: addressState.addresses.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(height: 200.h),
                        Center(
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
                                'Tap + to add your first address',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.all(16.w),
                      itemCount:
                          addressState.addresses.length +
                          (addressState.isStale ? 1 : 0),
                      separatorBuilder: (_, __) => AppSpacing.h12,
                      itemBuilder: (context, index) {
                        // Show stale warning at top
                        if (index == 0 && addressState.isStale) {
                          return Container(
                            padding: EdgeInsets.all(12.w),
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
                          );
                        }

                        final addressIndex = addressState.isStale
                            ? index - 1
                            : index;
                        final address = addressState.addresses[addressIndex];

                        return Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: address.selected
                                ? AppColors.green10
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: address.selected
                                  ? AppColors.green
                                  : AppColors.grey.withOpacity(0.3),
                              width: address.selected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8.w,
                                      vertical: 4.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.green,
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: Text(
                                      address.addressTypeLabel,
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
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
                              AppSpacing.h12,
                              Text(
                                address.fullName,
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
                        );
                      },
                    ),
            ),
    );
  }

  Future<void> _handleDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 14.sp, color: AppColors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Address deleted successfully'),
              backgroundColor: AppColors.green,
            ),
          );
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
}
