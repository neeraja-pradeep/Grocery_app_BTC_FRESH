import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/widgets/app_text.dart';

/// Add to Cart button with two states:
/// 1. Initial: "Add" button
/// 2. Added: Quantity selector with minus/plus buttons
/// Animates smoothly between states with cross fade
class AddToCartButton extends StatelessWidget {
  const AddToCartButton({
    super.key,
    required this.quantity,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    required this.onViewCart,
  });

  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onViewCart;

  bool get isInCart => quantity > 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: AnimatedCrossFade(
        firstChild: _AddButton(onAdd: onAdd),
        secondChild: _QuantitySelector(
          quantity: quantity,
          onIncrement: onIncrement,
          onDecrement: onDecrement,
          onViewCart: onViewCart,
        ),
        crossFadeState: isInCart
            ? CrossFadeState.showSecond
            : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }
}

/// Initial Add button
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.green,
          borderRadius: BorderRadius.circular(12.r),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_shopping_cart,
              color: AppColors.white,
              size: 18,
            ),
            AppSpacing.w8,
            const AppText(
              text: 'Add',
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ],
        ),
      ),
    );
  }
}

/// Quantity selector with minus/plus buttons and View Cart button
class _QuantitySelector extends StatefulWidget {
  const _QuantitySelector({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
    required this.onViewCart,
  });

  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onViewCart;

  @override
  State<_QuantitySelector> createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<_QuantitySelector>
    with TickerProviderStateMixin {
  late AnimationController _quantityScaleController;
  late Animation<double> _quantityScale;

  @override
  void initState() {
    super.initState();
    _quantityScaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _quantityScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _quantityScaleController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void didUpdateWidget(_QuantitySelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantity != oldWidget.quantity) {
      _quantityScaleController.forward().then((_) {
        _quantityScaleController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _quantityScaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Quantity selector row with animation
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.green10,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: AppColors.green60, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _AnimatedIconButton(
                onTap: widget.onDecrement,
                icon: Icons.remove,
                isPositive: false,
              ),
              AppSpacing.w12,
              ScaleTransition(
                scale: _quantityScale,
                child: AppText(
                  text: '${widget.quantity}',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green,
                ),
              ),
              AppSpacing.w12,
              _AnimatedIconButton(
                onTap: widget.onIncrement,
                icon: Icons.add,
                isPositive: true,
              ),
            ],
          ),
        ),
        AppSpacing.h8,
        // View Cart button with press animation
        _AnimatedPressButton(onTap: widget.onViewCart, label: 'View Cart'),
      ],
    );
  }
}

/// Animated icon button with scale effect on press
class _AnimatedIconButton extends StatefulWidget {
  const _AnimatedIconButton({
    required this.onTap,
    required this.icon,
    required this.isPositive,
  });

  final VoidCallback onTap;
  final IconData icon;
  final bool isPositive;

  @override
  State<_AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<_AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: widget.isPositive ? AppColors.green : AppColors.white,
            shape: BoxShape.circle,
            border: widget.isPositive
                ? null
                : Border.all(color: AppColors.green, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: widget.isPositive
                    ? AppColors.green.withValues(alpha: 0.3)
                    : Colors.transparent,
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Icon(
            widget.icon,
            color: widget.isPositive ? AppColors.white : AppColors.green,
            size: 16,
          ),
        ),
      ),
    );
  }
}

/// Animated press button
class _AnimatedPressButton extends StatefulWidget {
  const _AnimatedPressButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  State<_AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<_AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
    });
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.green.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: AppText(
            text: widget.label,
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
