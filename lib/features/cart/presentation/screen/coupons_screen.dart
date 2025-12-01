import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/app_text.dart';
import '../components/coupen_card.dart';
import '../components/input_field.dart';
import '../../application/providers/coupon_providers.dart';
import '../../application/states/coupon_state.dart';
import '../../domain/entities/coupon.dart';

/// Coupons Screen with 30-second polling for real-time updates
/// Uses Riverpod to watch coupon list from API with automatic refresh
class CouponsScreen extends ConsumerStatefulWidget {
  const CouponsScreen({super.key});

  @override
  ConsumerState<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends ConsumerState<CouponsScreen> {
  final TextEditingController _couponController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Polling starts automatically when provider is initialized
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon(String code) async {
    await _showApplyingBottomSheet(code);
    if (mounted) {
      Navigator.pop(context, code);
    }
  }

  Future<void> _showApplyingBottomSheet(String code) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (bottomSheetContext) {
        // Auto close after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (bottomSheetContext.mounted) {
            Navigator.pop(bottomSheetContext); // Close bottom sheet
          }
        });

        return Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: 'Applying coupon',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
              SizedBox(height: 24.h),
              LinearProgressIndicator(
                minHeight: 12.h,
                borderRadius: BorderRadius.circular(50.r),
                backgroundColor: AppColors.grey.withValues(alpha: 0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.loaderGreen,
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ),
        );
      },
    );
  }

  void _filterCoupons(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  /// Filter coupons based on search query
  List<Coupon> _getFilteredCoupons(List<Coupon> allCoupons) {
    if (_searchQuery.isEmpty) {
      return allCoupons;
    }
    return allCoupons
        .where((coupon) => coupon.name.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    // Watch coupon state from Riverpod provider (with 30-second polling)
    final couponState = ref.watch(couponControllerProvider);

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
          text: 'Apply Coupon',
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
        actions: [
          // Show refresh indicator when polling
          if (couponState.isRefreshing)
            Padding(
              padding: EdgeInsets.only(right: 16.w),
              child: Center(
                child: SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.couponGreen,
                  ),
                ),
              ),
            ),
        ],
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
              child: _buildBody(couponState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(CouponState state) {
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
              text: 'Failed to load coupons',
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.grey,
            ),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                ref.read(couponControllerProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Get all coupons (only active/available ones)
    final allCoupons = state.activeCoupons;
    final filteredCoupons = _getFilteredCoupons(allCoupons);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Coupon Input Field
        Padding(
          padding: EdgeInsets.all(16.w),
          child: AppInputField(
            couponController: _couponController,
            onChanged: _filterCoupons,
          ),
        ),

        // Available Coupons Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: AppText(
            text: 'Available coupons',
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
          ),
        ),
        SizedBox(height: 16.h),

        // Coupons List
        Expanded(
          child: filteredCoupons.isEmpty
              ? Center(
                  child: AppText(
                    text: _searchQuery.isEmpty
                        ? 'No coupons available'
                        : 'No coupons found',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w400,
                    color: AppColors.grey,
                  ),
                )
              : ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: filteredCoupons.length,
                  separatorBuilder: (context, index) => SizedBox(height: 16.h),
                  itemBuilder: (context, index) {
                    final coupon = filteredCoupons[index];
                    return CouponCard(
                      coupon: CouponModel(
                        code: coupon.name,
                        title:
                            'Get ${coupon.discountPercentage}% OFF on your order',
                        description: coupon.description,
                      ),
                      onApply: () => _applyCoupon(coupon.name),
                    );
                  },
                ),
        ),

        // Terms and Conditions
        Padding(
          padding: EdgeInsets.all(16.w),
          child: Center(
            child: AppText(
              text: 'Terms and Conditions Apply',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
