import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/widgets/app_snackbar.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../auth/application/states/auth_state.dart';
import '../../../cart/application/providers/checkout_line_provider.dart';
import '../../domain/entities/product_variant.dart';

class ProductSearchCard extends ConsumerWidget {
  final ProductVariant variant;
  final VoidCallback? onTap;

  const ProductSearchCard({super.key, required this.variant, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      child: Stack(
        clipBehavior: Clip.none, // Allow button to float outside
        children: [
          // MAIN CARD CONTENT
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      color: Colors.grey[100],
                    ),
                    child: variant.media.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.network(
                              variant.media.first.imageUrl.startsWith('http')
                                  ? variant.media.first.imageUrl
                                  : 'https://${variant.media.first.imageUrl}',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[400],
                                  size: 32.sp,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.image_not_supported,
                            color: Colors.grey[400],
                            size: 32.sp,
                          ),
                  ),

                  SizedBox(width: 12.w),

                  // Product Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          variant.name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: 4.h),

                        // Weight/Stock Unit
                        if (variant.stockUnit != null &&
                            variant.stockUnit!.isNotEmpty)
                          Text(
                            variant.stockUnit!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[600],
                            ),
                          ),

                        SizedBox(height: 8.h),

                        // Price Row
                        Row(
                          children: [
                            // Discounted Price (if available)
                            if (variant.discountedPrice != null &&
                                variant.discountedPrice! > 0) ...[
                              Text(
                                '₹${variant.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[500],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '₹${variant.discountedPrice!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ] else ...[
                              Text(
                                '₹${variant.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ],
                        ),

                        SizedBox(height: 8.h),

                        // Stock status
                        if (variant.status) ...[
                          Text(
                            'In Stock',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Out of stock',
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.red[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // FLOATING ADD BUTTON (+)
          // Only show if variant is in stock
          if (variant.status)
            Positioned(
              top: -8.h, // Negative to float outside
              right: -8.w, // Negative to float outside
              child: GestureDetector(
                onTap: () async {
                  // Block guests from adding to cart
                  final authState = ref.read(authProvider);
                  final isGuest = authState is GuestMode;

                  if (isGuest) {
                    AppSnackbar.info(
                      context,
                      'Please login to add items to cart',
                    );
                    return;
                  }

                  try {
                    await ref
                        .read(checkoutLineControllerProvider.notifier)
                        .addToCart(productVariantId: variant.id, quantity: 1);
                    if (context.mounted) {
                      AppSnackbar.success(
                        context,
                        '${variant.name} added to cart',
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppSnackbar.error(context, 'Unable to add item to cart');
                    }
                  }
                },
                child: Container(
                  width: 28.w,
                  height: 28.w,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: const Color(0xFF8cc727),
                      width: 1.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4.r,
                        offset: Offset(0, 2.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add,
                    color: const Color(0xFF00695C),
                    size: 16.sp,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
