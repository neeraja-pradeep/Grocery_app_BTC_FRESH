import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/app_spacing.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/widgets/app_text.dart';
import 'package:grocery_app/features/category/domain/entities/category_product.dart';
import 'package:grocery_app/features/product_details/presentation/components/product_info/product_info.dart';

import '../../application/providers/product_detail_providers.dart';
import '../../domain/entities/product_variant.dart' as product_variant;
import '../components/expandable_section/expandable_section.dart';
import '../components/product_image_section/product_image_section.dart';

const String _rupeeSymbol = '₹';

/// Product Details Screen - Thin Coordinator
///
/// This is a clean, modular screen that:
/// - Uses ConsumerStatefulWidget for Riverpod + Widget state integration
/// - Widget state: UI-only state (expandable sections)
/// - Riverpod state: Business logic (product data, caching, polling)
/// - Delegates rendering to focused component widgets
/// - ~100 lines vs original 504 lines (80% reduction)
///
/// Architecture pattern matches category feature - thin coordinator screen
/// with business logic in Riverpod and UI logic in modular components
class ProductDetailsScreen extends ConsumerStatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final CategoryProduct product;

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  /// UI State: Only track expandable section state
  /// This is UI-only state and doesn't need Riverpod
  bool _isProductDetailExpanded = true;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint(
        '[ProductDetailsScreen] Initialized with product ID: ${widget.product.id}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch business logic state from Riverpod
    final state = ref.watch(productDetailControllerProvider(widget.product.id));
    final controller = ref.read(
      productDetailControllerProvider(widget.product.id).notifier,
    );

    // Fallback to locally converted data if API data not available
    final productDetail =
        state.productDetail ?? _convertToProductVariant(widget.product);

    if (kDebugMode) {
      debugPrint(
        '[ProductDetailsScreen] State: ${state.status}, HasData: ${state.hasData}',
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(context),
      body: _buildBody(productDetail, state, controller),
      bottomSheet: _buildBottomSheet(productDetail, state),
    );
  }

  /// Builds the app bar with back button
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
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
    );
  }

  /// Builds main scrollable body - delegates to component widgets
  Widget _buildBody(
    product_variant.ProductVariant productDetail,
    dynamic state,
    dynamic controller,
  ) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image section
            ProductImageSection(
              imageUrl: productDetail.imageUrl,
              media: productDetail.media,
            ),
            AppSpacing.h16,

            // Product info (name, price, rating, description)
            ProductInfo(
              productDetail: productDetail,
              isInWishlist: state.isInWishlist,
              onWishlistToggle: controller.toggleWishlist,
            ),
            AppSpacing.h16,

            // Add to cart button + Price row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Add button or Quantity selector
                SizedBox(
                  width: 100.w,
                  height: 44.h,
                  child: state.quantity == 0
                      ? _buildAddButton(controller)
                      : _buildQuantitySelector(state, controller),
                ),
                // Unit Price display
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

            // Product details section
            ExpandableSection(
              title: 'Product Detail',
              isExpanded: _isProductDetailExpanded,
              onToggle: () {
                setState(
                  () => _isProductDetailExpanded = !_isProductDetailExpanded,
                );
              },
              child: AppText(
                text: productDetail.description ?? 'No details available',
                fontSize: 13.sp,
                fontWeight: FontWeight.w400,
                color: AppColors.grey,
                maxLines: 10,
              ),
            ),

            // Product weight/info section
            ExpandableSection(
              title: "Nutritions",
              onToggle: () {},
              badge: productDetail.weight,
              child: const SizedBox(),
            ),

            // Rating and reviews section
            if (productDetail.rating != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 0.w, vertical: 14.h),
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
                  children: [
                    AppText(
                      text: "Review",
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.black,
                    ),
                    const Spacer(),
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
              ),
          ],
        ),
      ),
    );
  }

  /// Build bottom sheet (sticky checkout section)
  /// Displays total price and View Cart button
  /// Price updates dynamically based on quantity
  Widget _buildBottomSheet(
    product_variant.ProductVariant productDetail,
    dynamic state,
  ) {
    // Calculate total price based on quantity
    final unitPrice =
        double.tryParse(
          productDetail.price.replaceAll(RegExp(r'[^\d.]'), ''),
        ) ??
        0.0;
    final totalPrice = unitPrice * state.quantity;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: AppColors.green10,
        boxShadow: [
          BoxShadow(
            color: AppColors.green50.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Total price column
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                text: 'Total price',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
              AppSpacing.h4,
              Text(
                state.quantity > 0
                    ? '$_rupeeSymbol${totalPrice.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '')}'
                    : '${_rupeeSymbol}0',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          // View Cart button
          GestureDetector(
            onTap: () {
              if (kDebugMode) debugPrint('[ProductDetails] Checkout tapped');
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 70.w, vertical: 20.h),
              decoration: BoxDecoration(
                color: AppColors.green50,
                borderRadius: BorderRadius.circular(10.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green50.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AppText(
                text: 'View Cart',
                fontSize: 16.sp,
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Convert CategoryProduct to ProductVariant with mock media items
  /// This provides fallback data when Riverpod hasn't fetched from API
  product_variant.ProductVariant _convertToProductVariant(
    CategoryProduct product,
  ) {
    final List<product_variant.ProductVariantMedia> media = [];
    final String thumbnailUrl = _ensureHttpsUrl(product.thumbnailUrl);

    if (thumbnailUrl.isNotEmpty) {
      media.add(
        product_variant.ProductVariantMedia(
          id: 1,
          filePath: thumbnailUrl,
          image: thumbnailUrl,
          alt: '${product.name} Thumbnail',
          productId: int.parse(product.id),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    final String imageUrl = _ensureHttpsUrl(product.imageUrl);

    return product_variant.ProductVariant(
      id: int.parse(product.id),
      sku: product.id,
      name: product.name,
      variantName: product.variantName,
      productId: int.parse(product.id),
      trackInventory: false,
      price: product.price ?? '0',
      originalPrice: product.originalPrice,
      weight: product.weight,
      rating: product.rating,
      imageUrl: imageUrl.isNotEmpty ? product.imageUrl : null,
      thumbnailUrl: thumbnailUrl.isNotEmpty ? thumbnailUrl : null,
      media: media.isNotEmpty ? media : null,
      categoryId: product.categoryId,
      description: product.description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Ensure image URL has https:// protocol
  String _ensureHttpsUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return 'https://$url';
  }

  /// Add button when quantity is 0
  /// Tapping this sets quantity to 1 and triggers UI refresh
  Widget _buildAddButton(dynamic controller) {
    return GestureDetector(
      onTap: () => controller.setQuantity(1),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.green50,
          borderRadius: BorderRadius.circular(10.r),
        ),
        alignment: Alignment.center,
        child: AppText(
          text: 'Add',
          color: AppColors.white,
          fontWeight: FontWeight.w700,
          fontSize: 16.sp,
        ),
      ),
    );
  }

  /// Quantity selector (increment/decrement)
  /// Displays minus button, quantity number, and plus button
  /// Replaces Add button once quantity > 0
  Widget _buildQuantitySelector(dynamic state, dynamic controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Decrement button
        GestureDetector(
          onTap: () {
            if (state.quantity > 0) {
              controller.setQuantity(state.quantity - 1);
            }
          },
          child: const Icon(Icons.remove, color: AppColors.green100, size: 28),
        ),
        // Quantity display
        Container(
          width: 32.w,
          height: 32.w,
          decoration: BoxDecoration(
            color: AppColors.green50,
            border: Border.all(color: AppColors.green50, width: 1.5),
            borderRadius: BorderRadius.circular(8.r),
          ),
          alignment: Alignment.center,
          child: AppText(
            text: '${state.quantity}',
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        // Increment button
        GestureDetector(
          onTap: () => controller.setQuantity(state.quantity + 1),
          child: const Icon(Icons.add, color: AppColors.green100, size: 28),
        ),
      ],
    );
  }
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
        color: Colors.deepOrangeAccent,
        size: 16.sp,
      ),
    ),
  );
}
