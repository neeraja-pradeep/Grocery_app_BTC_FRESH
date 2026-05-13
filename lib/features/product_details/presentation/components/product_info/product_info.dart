import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/widgets/app_snackbar.dart';
import '../../../../../core/widgets/app_text.dart';

import '../../../domain/entities/product_variant.dart';
import '../../helpers/product_details_helpers.dart';

/// Product information section with name, weight, price, rating
class ProductInfo extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product name
        Row(
          children: [
            AppText(
              text: productDetail.variantName ?? productDetail.name,
              fontSize: 24.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
              maxLines: 2,
            ),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                final success = await onWishlistToggle();
                if (context.mounted && !success) {
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
                  isInWishlist ? Icons.favorite : Icons.favorite_border,
                  color: isInWishlist ? Colors.red : AppColors.grey,
                  size: 26.sp,
                ),
              ),
            ),
          ],
        ),

        // Weight/Quantity
        if (productDetail.weight != null && productDetail.weight!.isNotEmpty)
          AppText(
            text: parseWeight(productDetail.weight!),
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.grey,
          ),
        if (productDetail.weight != null && productDetail.weight!.isNotEmpty)
          AppSpacing.h12,
      ],
    );
  }
}
