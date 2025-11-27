import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/features/cart/presentation/components/coupen_card.dart';
import 'package:grocery_app/features/cart/presentation/components/input_field.dart';

class CouponsScreen extends StatefulWidget {
  const CouponsScreen({super.key});

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final TextEditingController _couponController = TextEditingController();

  final List<CouponModel> _availableCoupons = [
    CouponModel(
      code: 'EASYGROS',
      title: 'Get 10% OFF on your first order',
      description:
          'Perfect for new users. Save on your first basket of groceries fresh, fast, and delivered to your door!',
    ),
    CouponModel(
      code: 'FRESH10',
      title: 'Get 10% OFF on your first order',
      description:
          'Perfect for new users. Save on your first basket of groceries fresh, fast, and delivered to your door!',
    ),
    CouponModel(
      code: 'SAVE50',
      title: 'Get 10% OFF on your first order',
      description:
          'Perfect for new users. Save on your first basket of groceries fresh, fast, and delivered to your door!',
    ),
    CouponModel(
      code: 'ORGNC20',
      title: 'Get 10% OFF on your first order',
      description:
          'Perfect for new users. Save on your first basket of groceries fresh, fast, and delivered to your door!',
    ),
  ];

  List<CouponModel> _filteredCoupons = [];

  @override
  void initState() {
    super.initState();
    _filteredCoupons = _availableCoupons;
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
              Text(
                'Applying coupon',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
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
      if (query.isEmpty) {
        _filteredCoupons = _availableCoupons;
      } else {
        _filteredCoupons = _availableCoupons
            .where(
              (coupon) =>
                  coupon.code.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
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
          'Apply Coupon',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
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
              child: Column(
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
                    child: Text(
                      'Available coupons',
                      style: TextStyle(
                        color: AppColors.black,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Coupons List
                  Expanded(
                    child: _filteredCoupons.isEmpty
                        ? Center(
                            child: Text(
                              'No coupons found',
                              style: TextStyle(
                                color: AppColors.grey,
                                fontSize: 14.sp,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            itemCount: _filteredCoupons.length,
                            separatorBuilder: (context, index) =>
                                SizedBox(height: 16.h),
                            itemBuilder: (context, index) {
                              final coupon = _filteredCoupons[index];
                              return CouponCard(
                                coupon: coupon,
                                onApply: () => _applyCoupon(coupon.code),
                              );
                            },
                          ),
                  ),

                  // Terms and Conditions
                  Padding(
                    padding: EdgeInsets.all(16.w),
                    child: Center(
                      child: Text(
                        'Terms and Conditions Apply',
                        style: TextStyle(
                          color: AppColors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 16.sp,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
