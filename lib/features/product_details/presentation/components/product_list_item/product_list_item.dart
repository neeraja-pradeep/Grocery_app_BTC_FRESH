import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../app/theme/app_spacing.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../core/widgets/app_text.dart';

/// Product List Item Widget
/// Displays a product card with image, details, price and quantity selector
class ProductListItem extends StatelessWidget {
  const ProductListItem({
    super.key,
    required this.productName,
    required this.weight,
    required this.price,
    required this.imageUrl,
    required this.quantity,
    required this.onQuantityChanged,
    required this.pricePerUnit,
  });

  final String productName;
  final String weight;
  final String price;
  final String imageUrl;
  final int quantity;
  final Function(int) onQuantityChanged;
  final String pricePerUnit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.grey.withValues(alpha: 0.15),
            width: 1.h,
          ),
          top: BorderSide(
            color: AppColors.grey.withValues(alpha: 0.15),
            width: 1.h,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            width: 70.w,
            height: 70.w,
            decoration: BoxDecoration(
              color: AppColors.grey.withValues(alpha: 0.1),
              // borderRadius: BorderRadius.circular(10.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.grey.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.image_not_supported,
                        color: AppColors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          AppSpacing.w8,

          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Price in green
                AppText(
                  text: price,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green50,
                ),
                AppSpacing.h4,

                // Product Name
                AppText(
                  text: productName,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                  maxLines: 2,
                ),
                AppSpacing.h4,

                // Weight and Price Per Unit
                Row(
                  children: [
                    AppText(
                      text: '$weight • $pricePerUnit/kg',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w500,
                      color: AppColors.grey,
                    ),
                    const Spacer(),
                    SizedBox(
                      width: 100.w,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (quantity > 0) {
                                onQuantityChanged(quantity - 1);
                              }
                            },
                            child: Container(
                              width: 24.w,
                              height: 24.w,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(5.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.grey.withValues(
                                      alpha: 0.19,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.remove,
                                color: AppColors.green100,
                                size: 14,
                                weight: 900,
                              ),
                            ),
                          ),
                          AppSpacing.w4,
                          Container(
                            width: 24.w,
                            height: 24.w,
                            decoration: BoxDecoration(
                              color: AppColors.green100,
                              borderRadius: BorderRadius.circular(5.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.green100.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: AppText(
                              text: '$quantity',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                          AppSpacing.w4,
                          GestureDetector(
                            onTap: () => onQuantityChanged(quantity + 1),
                            child: Container(
                              width: 24.w,
                              height: 24.w,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(5.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.grey.withValues(
                                      alpha: 0.19,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.add,
                                color: AppColors.green100,
                                size: 14,
                                weight: 900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AppSpacing.w8,

          // Quantity Selector
        ],
      ),
    );
  }
}
