import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/widgets/app_text.dart';

/// Cart item card component
/// Displays product image, name, price, and quantity controls
class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.weight,
    required this.pricePerKg,
    required this.quantity,
    required this.stockBadge,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  final String? imageUrl;
  final String name;
  final String weight;
  final String pricePerKg;
  final int quantity;
  final String stockBadge;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          // Product image
          _buildProductImage(),
          SizedBox(width: 12.w),

          // Product info and controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStockBadge(),
                SizedBox(height: 4.h),
                _buildProductName(),
                SizedBox(height: 6.h),
                _buildPriceInfo(),
              ],
            ),
          ),

          SizedBox(width: 12.w),

          // Quantity controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [_buildQuantityControls()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage() {
    return Container(
      width: 60.w,
      height: 60.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.r),
        color: AppColors.grey.withValues(alpha: 0.1),
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: Image.asset(
                imageUrl!,
                fit: BoxFit.fitWidth,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.grey,
                    size: 30.sp,
                  );
                },
              ),
            )
          : Icon(
              Icons.shopping_basket_outlined,
              color: AppColors.grey,
              size: 30.sp,
            ),
    );
  }

  Widget _buildStockBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 2.h),
      child: AppText(
        text: stockBadge,
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF689F38),
      ),
    );
  }

  Widget _buildProductName() {
    return AppText(
      text: name,
      fontSize: 13.sp,
      fontWeight: FontWeight.w500,
      color: AppColors.black,
      maxLines: 2,
    );
  }

  Widget _buildPriceInfo() {
    return Row(
      children: [
        AppText(
          text: pricePerKg,
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
          color: AppColors.grey,
        ),
        SizedBox(width: 4.w),
        AppText(
          text: '/ kg',
          fontSize: 12.sp,
          fontWeight: FontWeight.w400,
          color: AppColors.grey.withValues(alpha: 0.7),
        ),
      ],
    );
  }

  Widget _buildQuantityControls() {
    return Row(
      children: [
        // Decrement button
        _buildControlButton(icon: Icons.remove, onTap: onDecrement),
        SizedBox(width: 4.w),

        // Quantity display
        Container(
          width: 32.w,
          height: 26.h,
          decoration: BoxDecoration(
            color: const Color(0xFF8BC34A),
            borderRadius: BorderRadius.circular(4.r),
          ),
          alignment: Alignment.center,
          child: AppText(
            text: quantity.toString(),
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ),
        SizedBox(width: 4.w),

        // Increment button
        _buildControlButton(icon: Icons.add, onTap: onIncrement),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32.w,
        height: 26.h,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(
            color: AppColors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4.r),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 16.sp, color: AppColors.grey),
      ),
    );
  }
}
