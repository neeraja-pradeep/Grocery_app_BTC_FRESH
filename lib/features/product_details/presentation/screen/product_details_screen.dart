import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/app_spacing.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/widgets/app_text.dart';
import 'package:grocery_app/features/category/domain/entities/category_product.dart';

import '../../domain/entities/product_detail.dart' as product_detail;
import '../components/expandable_section/expandable_section.dart';
import '../components/product_image_section/product_image_section.dart';
import '../components/product_list_item/product_list_item.dart';

const String _rupeeSymbol = '₹';

/// Product Details Screen
/// Shows detailed product information with expandable sections
/// UI-only mode - displays data from passed product object
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final CategoryProduct product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 0;
  bool _isInWishlist = false;
  bool _isProductDetailExpanded = false;

  // Related products quantities
  late Map<String, int> _relatedProductsQuantities = {};

  @override
  void initState() {
    super.initState();
    _initializeRelatedProductsQuantities();
  }

  void _initializeRelatedProductsQuantities() {
    // Initialize quantities for related products (you can modify this based on your data)
    _relatedProductsQuantities = {'yellow_cherry': 0, 'roma_vf': 0};
  }

  /// Convert CategoryProduct to ProductDetail
  product_detail.ProductDetail _convertToProductDetail(
    CategoryProduct product,
  ) {
    return product_detail.ProductDetail(
      id: product.id,
      name: product.name,
      variantId: product.variantId,
      variantName: product.variantName,
      price: product.price,
      originalPrice: product.originalPrice,
      weight: product.weight,
      rating: product.rating,
      imageUrl: product.imageUrl,
      thumbnailUrl: product.thumbnailUrl,
      categoryId: product.categoryId,
      description: product.description,
    );
  }

  @override
  Widget build(BuildContext context) {
    final productDetail = _convertToProductDetail(widget.product);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.white,
        leading: Padding(
          padding: EdgeInsets.all(7.w),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 45.h,
              width: 45.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.grey.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: AppColors.black,
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with Wishlist Button
              ProductImageSection(
                imageUrl: productDetail.imageUrl,
                isInWishlist: _isInWishlist,
                onWishlistToggle: () {
                  setState(() => _isInWishlist = !_isInWishlist);
                },
              ),
              AppSpacing.h16,

              // Product Name and Weight.......................
              Row(
                children: [
                  AppText(
                    text: productDetail.variantName,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                    maxLines: 2,
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      setState(() => _isInWishlist = !_isInWishlist);
                    },
                    child: Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: const BoxDecoration(
                        color: AppColors.white,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _isInWishlist ? Icons.favorite : Icons.favorite_border,
                        color: _isInWishlist ? Colors.red : AppColors.green100,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
              if (productDetail.weight != null &&
                  productDetail.weight!.isNotEmpty)
                AppText(
                  text: productDetail.weight!,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.grey,
                ),
              AppSpacing.h16,

              // Add Button and Price Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Add to Cart Button
                  SizedBox(
                    width: 100.w,
                    height: 44.h,
                    child: _quantity == 0
                        ? GestureDetector(
                            onTap: () => setState(() => _quantity = 1),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 10.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.green50,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              alignment: Alignment.center,
                              child: AppText(
                                text: 'Add',
                                color: AppColors.green100,
                                fontWeight: FontWeight.w700,
                                fontSize: 16.sp,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() {
                                  if (_quantity > 0) _quantity--;
                                }),
                                child: const Icon(
                                  Icons.remove,
                                  color: AppColors.grey,
                                  size: 28,
                                  weight: 900,
                                ),
                              ),
                              Container(
                                width: 32.w,
                                height: 32.w,
                                decoration: BoxDecoration(
                                  color: AppColors.green50,
                                  border: Border.all(
                                    color: AppColors.green50,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                alignment: Alignment.center,
                                child: AppText(
                                  text: '$_quantity',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.green100,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _quantity++),
                                child: const Icon(
                                  Icons.add,
                                  color: AppColors.green100,
                                  size: 28,
                                  weight: 900,
                                ),
                              ),
                            ],
                          ),
                  ),

                  // Price
                  Text(
                    '$_rupeeSymbol${productDetail.price}',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
              AppSpacing.h16,

              // Product Detail Section (Expandable)
              ExpandableSection(
                title: 'Product Detail',
                isExpanded: _isProductDetailExpanded,
                onToggle: () {
                  setState(
                    () => _isProductDetailExpanded = !_isProductDetailExpanded,
                  );
                },
                child: AppText(
                  text:
                      productDetail.description ??
                      'Apples Are Nutritious. Apples May Be Good For Weight Loss. '
                          'Apples May Be Good For Your Heart. As Part Of A Healthful And Varied Diet.',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.grey,
                  maxLines: 10,
                ),
              ),

              // Nutritions Section (Expandable)
              ExpandableSection(
                title: 'Nutritions',
                onToggle: () {},
                badge: '100gr',
                child: const SizedBox(),
              ),

              // Review Section
              GestureDetector(
                onTap: () {
                  // Navigate to review detail screen
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 14.h,
                  ),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText(
                        text: 'Review',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.green100,
                      ),
                      const Spacer(),
                      Row(
                        children: List.generate(
                          5,
                          (index) => Icon(
                            Icons.star_rounded,
                            color: Colors.deepOrange,
                            size: 18.sp,
                          ),
                        ),
                      ),
                      AppSpacing.w4,
                      Icon(
                        Icons.arrow_forward_ios,
                        color: AppColors.grey,
                        size: 16.sp,
                      ),
                    ],
                  ),
                ),
              ),

              // Product List Items
              ProductListItem(
                productName: 'Yellow Cherry\nTomatoes 250g',
                weight: '250g',
                price: '1.80',
                imageUrl: productDetail.imageUrl ?? '',
                quantity: _relatedProductsQuantities['yellow_cherry'] ?? 0,
                onQuantityChanged: (newQuantity) {
                  setState(() {
                    _relatedProductsQuantities['yellow_cherry'] = newQuantity;
                  });
                },
                pricePerUnit: '3,45',
              ),
              AppSpacing.h12,

              ProductListItem(
                productName: 'Roma VF\nTomatoes',
                weight: '500g',
                price: '1.60',
                imageUrl: productDetail.imageUrl ?? '',
                quantity: _relatedProductsQuantities['roma_vf'] ?? 0,
                onQuantityChanged: (newQuantity) {
                  setState(() {
                    _relatedProductsQuantities['roma_vf'] = newQuantity;
                  });
                },
                pricePerUnit: '2,85',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
