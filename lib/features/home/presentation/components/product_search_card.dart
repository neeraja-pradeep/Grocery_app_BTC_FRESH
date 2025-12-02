import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../domain/entities/product.dart';

class ProductSearchCard extends StatelessWidget {
  final Product product;
  final VoidCallback? onTap;

  const ProductSearchCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
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
                    child: product.displayImage.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: Image.network(
                              product.displayImage.startsWith('http')
                                  ? product.displayImage
                                  : 'https://${product.displayImage}',
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
                          product.name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        SizedBox(height: 4.h),

                        // Category
                        Text(
                          product.categoryName,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[600],
                          ),
                        ),

                        SizedBox(height: 8.h),

                        // Price and Rating Row
                        Row(
                          children: [
                            // Price
                            if (product.hasDiscount) ...[
                              Text(
                                '₹${product.defaultVariant?.price.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[500],
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              SizedBox(width: 4.w),
                            ],
                            Text(
                              '₹${product.displayPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: product.hasDiscount
                                    ? Colors.red
                                    : Colors.black87,
                              ),
                            ),

                            const Spacer(),

                            // Rating
                            if (product.rating != '0.0') ...[
                              Icon(
                                Icons.star,
                                size: 14.sp,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                product.rating,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),

                        SizedBox(height: 8.h),

                        // Variants info
                        if (product.hasVariants) ...[
                          Text(
                            '${product.availableVariants.length} variant${product.availableVariants.length != 1 ? 's' : ''} available',
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
          // Only show if product has variants (is available)
          if (product.hasVariants)
            Positioned(
              top: -8.h, // Negative to float outside
              right: -8.w, // Negative to float outside
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} added to cart'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
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
