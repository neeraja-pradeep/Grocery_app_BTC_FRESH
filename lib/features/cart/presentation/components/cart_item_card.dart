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
    this.isProcessing = false,
  });

  final String? imageUrl;
  final String name;
  final String weight;
  final String
  pricePerKg; // This is the effective price (discounted if applicable)
  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback? onRemove;

  // New fields for discount display
  final String? originalPrice; // Original price before discount
  final bool hasDiscount;
  final double discountPercentage;

  // Processing state - disables buttons while API call is in progress
  final bool isProcessing;

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
    // Show loading spinner when processing
    if (isProcessing) {
      return Row(
        children: [
          // Disabled decrement button
          _QuantityControlButton(
            icon: Icons.remove,
            onTap: () {},
            isDisabled: true,
          ),
          SizedBox(width: 4.w),

          // Quantity display with loading indicator
          Container(
            width: 32.w,
            height: 26.h,
            decoration: BoxDecoration(
              color: const Color(0xFF8BC34A).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4.r),
            ),
            alignment: Alignment.center,
            child: SizedBox(
              width: 14.w,
              height: 14.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            ),
          ),
          SizedBox(width: 4.w),

          // Disabled increment button
          _QuantityControlButton(
            icon: Icons.add,
            onTap: () {},
            isDisabled: true,
          ),
        ],
      );
    }

    return Row(
      children: [
        // Decrement button
        _QuantityControlButton(icon: Icons.remove, onTap: onDecrement),
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

        // Increment button (disabled if onIncrement is null - out of stock)
        _QuantityControlButton(
          icon: Icons.add,
          onTap: onIncrement ?? () {},
          isDisabled: onIncrement == null,
        ),
      ],
    );
  }
}

/// Animated quantity control button with border highlight effect
class _QuantityControlButton extends StatefulWidget {
  const _QuantityControlButton({
    required this.icon,
    required this.onTap,
    this.isDisabled = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isDisabled;

  @override
  State<_QuantityControlButton> createState() => _QuantityControlButtonState();
}

class _QuantityControlButtonState extends State<_QuantityControlButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _borderColorAnimation;
  late Animation<Color?> _iconColorAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _borderColorAnimation = ColorTween(
      begin: AppColors.grey.withValues(alpha: 0.3),
      end: const Color(0xFF8BC34A),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _iconColorAnimation = ColorTween(
      begin: AppColors.grey,
      end: const Color(0xFF8BC34A),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.isDisabled) return;
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    // Show disabled state
    if (widget.isDisabled) {
      return Container(
        width: 32.w,
        height: 26.h,
        decoration: BoxDecoration(
          color: AppColors.grey.withValues(alpha: 0.1),
          border: Border.all(
            color: AppColors.grey.withValues(alpha: 0.2),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(4.r),
        ),
        alignment: Alignment.center,
        child: Icon(
          widget.icon,
          size: 16.sp,
          color: AppColors.grey.withValues(alpha: 0.4),
        ),
      );
    }

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 32.w,
              height: 26.h,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(
                  color: _borderColorAnimation.value ?? AppColors.grey,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(4.r),
              ),
              alignment: Alignment.center,
              child: Icon(
                widget.icon,
                size: 16.sp,
                color: _iconColorAnimation.value ?? AppColors.grey,
              ),
            ),
          );
        },
      ),
    );
  }
}
