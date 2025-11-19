import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/app_spacing.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/widgets/app_text.dart';
import '../../../domain/entities/product_detail.dart';

const String _rupeeSymbol = '\u20B9';

/// Product information section with name, weight, price, rating
class ProductInfo extends StatelessWidget {
  const ProductInfo({super.key, required this.productDetail});

  final ProductDetail productDetail;

  @override
  Widget build(BuildContext context) {
    final priceValue = _formatPrice(productDetail.price);
    final originalPriceValue = _formatPrice(productDetail.originalPrice);
    final discount = _calculateDiscount(
      productDetail.price,
      productDetail.originalPrice,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product name
        AppText(
          text: productDetail.variantName,
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: AppColors.green100,
          maxLines: 2,
        ),
        AppSpacing.h8,

        // Weight/Quantity
        if (productDetail.weight != null && productDetail.weight!.isNotEmpty)
          AppText(
            text: productDetail.weight!,
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.grey,
          ),
        if (productDetail.weight != null && productDetail.weight!.isNotEmpty)
          AppSpacing.h12,

        // Price row
        Row(
          children: [
            AppText(
              text: _rupeeSymbol,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.green,
            ),
            AppSpacing.w4,
            AppText(
              text: priceValue ?? 'N/A',
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.green,
            ),
            if (originalPriceValue != null &&
                originalPriceValue != priceValue) ...[
              AppSpacing.w12,
              AppText(
                text: '$_rupeeSymbol$originalPriceValue',
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.grey,
                decoration: TextDecoration.lineThrough,
              ),
            ],
            if (discount != null) ...[
              AppSpacing.w12,
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: AppText(
                  text: '$discount% Off',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ],
        ),
        AppSpacing.h16,

        // Rating and reviews
        if (productDetail.rating != null)
          Row(
            children: [
              _buildRatingStars(productDetail.rating!),
              AppSpacing.w8,
              AppText(
                text: '${productDetail.rating?.toStringAsFixed(1)}',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.green,
              ),
              if (productDetail.reviewCount != null) ...[
                AppSpacing.w12,
                AppText(
                  text: '(${productDetail.reviewCount} reviews)',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey,
                ),
              ],
            ],
          ),

        // Description
        if (productDetail.description?.isNotEmpty ?? false) ...[
          AppSpacing.h16,
          AppText(
            text: 'Description',
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.green100,
          ),
          AppSpacing.h8,
          AppText(
            text: productDetail.description!,
            fontSize: 12.sp,
            fontWeight: FontWeight.w400,
            color: AppColors.grey,
            maxLines: 3,
          ),
        ],
      ],
    );
  }

  /// Build rating stars widget
  Widget _buildRatingStars(double rating) {
    return Row(
      children: List.generate(
        5,
        (index) => Icon(
          index < rating.floor()
              ? Icons.star
              : index < rating
              ? Icons.star_half
              : Icons.star_outline,
          color: Colors.amber,
          size: 16.sp,
        ),
      ),
    );
  }

  /// Format price value
  String? _formatPrice(String? price) {
    if (price == null || price.isEmpty) return null;

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

  /// Calculate discount percentage
  int? _calculateDiscount(String? price, String? originalPrice) {
    final priceNum = double.tryParse(
      (price ?? '').replaceAll(RegExp(r'[^\d.]'), ''),
    );
    final originalNum = double.tryParse(
      (originalPrice ?? '').replaceAll(RegExp(r'[^\d.]'), ''),
    );

    if (priceNum == null ||
        originalNum == null ||
        originalNum <= 0 ||
        priceNum >= originalNum) {
      return null;
    }

    final discount = ((originalNum - priceNum) / originalNum * 100).round();
    return discount > 0 ? discount : null;
  }

  /// Trim trailing zeros
  String _trimTrailingZeros(String value) {
    return value.replaceFirst(RegExp(r'\.?0+$'), '');
  }
}
