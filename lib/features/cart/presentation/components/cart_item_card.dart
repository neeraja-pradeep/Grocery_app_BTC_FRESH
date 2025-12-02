import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/widgets/app_text.dart';

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
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    this.originalPrice,
    this.hasDiscount = false,
    this.discountPercentage = 0,
  });

  final String? imageUrl;
  final String name;
  final String weight;
  final String
  pricePerKg; // This is the effective price (discounted if applicable)
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback? onRemove;

  // New fields for discount display
  final String? originalPrice; // Original price before discount
  final bool hasDiscount;
  final double discountPercentage;

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
          // Product image with discount badge
          _buildProductImage(),
          SizedBox(width: 12.w),

          // Product info and controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductName(),
                SizedBox(height: 4.h),
                _buildWeightInfo(),
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
              child: Image.network(
                imageUrl!,
                fit: BoxFit.cover,
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

  Widget _buildProductName() {
    return AppText(
      text: name,
      fontSize: 13.sp,
      fontWeight: FontWeight.w500,
      color: AppColors.black,
      maxLines: 2,
    );
  }

  Widget _buildWeightInfo() {
    return AppText(
      text: '$weight g',
      fontSize: 11.sp,
      fontWeight: FontWeight.w400,
      color: AppColors.grey,
    );
  }

  Widget _buildPriceInfo() {
    return Row(
      children: [
        // Effective/Discounted price
        AppText(
          text: '₹$pricePerKg',
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: hasDiscount ? AppColors.couponGreen : AppColors.black,
        ),
        SizedBox(width: 6.w),
        // Original price with strikethrough if discounted
        if (hasDiscount && originalPrice != null) ...[
          AppText(
            text: '₹$originalPrice',
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.grey,
            decoration: TextDecoration.lineThrough,
          ),
        ],
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
