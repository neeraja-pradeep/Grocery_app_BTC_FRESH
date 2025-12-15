import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../core/widgets/app_text.dart';

import '../../../domain/entities/product_variant.dart';

/// Product information section with name, weight, price, rating
class ProductInfo extends StatefulWidget {
  const ProductInfo({
    super.key,
    required this.productDetail,
    required this.isInWishlist,
    required this.onWishlistToggle,
  });
  final bool isInWishlist;
  final Future<bool> Function() onWishlistToggle;
  final ProductVariant productDetail;

  @override
  State<ProductInfo> createState() => _ProductInfoState();
}

class _ProductInfoState extends State<ProductInfo> {
  /// Parse weight string and convert to normalized format (gm or kg)
  /// Examples: "500 gm" -> "500 gm", "1000 gm" -> "1 kg", "1200 gm" -> "1.2 kg"
  String _parseWeight(String weight) {
    try {
      // Remove extra spaces and convert to lowercase
      final cleanedWeight = weight.trim().toLowerCase();

      // Extract numeric value and unit using regex
      final regex = RegExp(r'([\d.]+)\s*([a-z]*)');
      final match = regex.firstMatch(cleanedWeight);

      if (match == null) return weight;

      final numericValue = double.tryParse(match.group(1) ?? '0') ?? 0;
      final unit = (match.group(2) ?? '').replaceAll(RegExp(r'[^a-z]'), '');

      // Determine if input is in grams or kilograms
      double valueInGrams = numericValue;

      if (unit.contains('k')) {
        // Already in kg, convert to grams
        valueInGrams = numericValue * 1000;
      }
      // else it's in grams or no unit specified (assume grams)

      // Convert back to appropriate unit
      if (valueInGrams >= 1000) {
        // Convert to kg
        final valueInKg = valueInGrams / 1000;
        // Remove trailing zeros after decimal
        final formatted = valueInKg
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'\.?0+$'), '');
        return '$formatted kg';
      } else {
        // Keep in grams, preserve decimal values
        final formatted = valueInGrams
            .toStringAsFixed(2)
            .replaceAll(RegExp(r'\.?0+$'), '');
        return '$formatted gm';
      }
    } catch (e) {
      // If parsing fails, return original weight
      return weight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product name
        Row(
          children: [
            AppText(
              text:
                  widget.productDetail.variantName ?? widget.productDetail.name,
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
              maxLines: 2,
            ),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                final success = await widget.onWishlistToggle();
                if (context.mounted && !success) {
                  // Show error message if toggle failed
                  AppSnackbar.info(
                    context,
                    'Please login to add items to wishlist',
                  );
                }
              },
              child: Container(
                width: 48.w,
                height: 48.w,
                alignment: Alignment.center,
                child: Icon(
                  widget.isInWishlist ? Icons.favorite : Icons.favorite_border,
                  color: widget.isInWishlist ? Colors.red : AppColors.grey,
                  size: 26.sp,
                ),
              ),
            ),
          ],
        ),

        // Weight/Quantity
        if (widget.productDetail.weight != null &&
            widget.productDetail.weight!.isNotEmpty)
          AppText(
            text: _parseWeight(widget.productDetail.weight!),
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.grey,
          ),
        if (widget.productDetail.weight != null &&
            widget.productDetail.weight!.isNotEmpty)
          AppSpacing.h12,
      ],
    );
  }
}
