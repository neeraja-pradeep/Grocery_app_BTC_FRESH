import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/app_spacing.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/widgets/app_text.dart';
import 'package:grocery_app/features/category/domain/entities/category_product.dart';

const String _rupeeSymbol = '\u20B9';

/// Individual product card displayed in product grid
/// Shows: Image + add-to-cart button | Name, weight, price + wishlist

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.colorScheme,
    required this.onAddToCart,
  });

  final CategoryProduct product;
  final ColorScheme colorScheme;
  final VoidCallback onAddToCart;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final image = product.imageUrl ?? product.thumbnailUrl;
    final formattedWeight = _formatWeight(product.weight);
    final priceValue = _formatPriceValue(product.price);
    final originalPriceValue = _formatPriceValue(product.originalPrice);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(18.r),
                      ),
                      color: AppColors.green10,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(18.r),
                      ),
                      child: _ProductImage(image: image),
                    ),
                  ),
                ),
                Positioned(
                  top: 8.h,
                  right: 5.w,
                  child: GestureDetector(
                    onTap: onAddToCart,
                    child: Container(
                      width: 29.w,
                      height: 29.w,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.add,
                        color: AppColors.white,
                        size: 17,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(10.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.pageTitle(text: product.variantName, maxLines: 1),

                AppSpacing.h8,
                if (formattedWeight != null)
                  AppText(
                    text: formattedWeight,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.grey,
                  ),
                if (formattedWeight != null) AppSpacing.h8,
                Row(
                  children: [
                    if (priceValue != null) ...[
                      const AppText.pageTitle(text: _rupeeSymbol),
                      AppSpacing.w4,
                      AppText.pageTitle(text: priceValue),
                      if (originalPriceValue != null &&
                          originalPriceValue != priceValue) ...[
                        AppSpacing.w8,
                        AppText(
                          text: '$_rupeeSymbol$originalPriceValue',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ],
                    ] else ...[
                      const AppText.pageTitle(text: 'N/A'),
                    ],
                    const Spacer(),
                    Icon(
                      Icons.favorite_border,
                      size: 22.sp,
                      color: isDark ? colorScheme.outline : AppColors.green100,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Product image with fallback handling (local/network/placeholder)

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.image});

  final String? image;

  @override
  Widget build(BuildContext context) {
    if (image == null || image!.isEmpty) {
      return Container(
        color: AppColors.green10,
        alignment: Alignment.center,
        child: const Icon(
          Icons.local_grocery_store_outlined,
          size: 28,
          color: AppColors.green100,
        ),
      );
    }

    if (image!.startsWith('assets/')) {
      return Image.asset(image!, fit: BoxFit.cover);
    }

    return Image.network(
      image!,
      fit: BoxFit.fitHeight,
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.green10,
        alignment: Alignment.center,
        child: const Icon(
          Icons.broken_image_outlined,
          size: 28,
          color: AppColors.green100,
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.green10,
          alignment: Alignment.center,
          child: SizedBox(
            width: 20.w,
            height: 20.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                        progress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
    );
  }
}

String? _formatWeight(String? weight) {
  if (weight == null) return null;

  final trimmed = weight.trim();
  if (trimmed.isEmpty) return null;

  final numeric = double.tryParse(trimmed);
  if (numeric != null) {
    final value = numeric % 1 == 0
        ? numeric.toInt().toString()
        : _trimTrailingZeros(numeric.toStringAsFixed(2));
    return '$value g';
  }

  final hasUnit = RegExp(r'[A-Za-z]').hasMatch(trimmed);
  if (hasUnit) {
    return trimmed;
  }

  return '$trimmed g';
}

String? _formatPriceValue(String? price) {
  if (price == null) return null;

  final trimmed = price.trim();
  if (trimmed.isEmpty) return null;

  var normalized = trimmed;
  if (normalized.startsWith(_rupeeSymbol)) {
    normalized = normalized.substring(_rupeeSymbol.length).trim();
  }

  if (normalized.isEmpty) return null;
  if (normalized.toUpperCase() == 'N/A') return null;

  final numeric = double.tryParse(normalized.replaceAll(',', ''));
  if (numeric != null) {
    return numeric % 1 == 0
        ? numeric.toInt().toString()
        : _trimTrailingZeros(numeric.toStringAsFixed(2));
  }

  return normalized;
}

String _trimTrailingZeros(String value) {
  return value.replaceFirst(RegExp(r'\.?0+$'), '');
}
