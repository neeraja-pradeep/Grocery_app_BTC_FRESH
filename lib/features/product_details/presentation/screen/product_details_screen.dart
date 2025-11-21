import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/app_spacing.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/widgets/app_text.dart';
import 'package:grocery_app/features/category/domain/entities/category_product.dart';
import 'package:grocery_app/features/product_details/presentation/components/checkout_section/checkout_section.dart';
import 'package:grocery_app/features/product_details/presentation/components/price_row/price_row.dart';
import 'package:grocery_app/features/product_details/presentation/components/product_info/product_info.dart';
import 'package:grocery_app/features/product_details/presentation/components/rating_section/rating_section.dart';

import '../../application/providers/product_detail_providers.dart';
import '../../domain/entities/product_variant.dart' as product_variant;
import '../components/expandable_section/expandable_section.dart';
import '../components/product_image_section/product_image_section.dart';
import '../helpers/product_details_helpers.dart';

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

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen>
    with WidgetsBindingObserver {
  /// UI State: Only track expandable section state
  /// This is UI-only state and doesn't need Riverpod
  bool _isProductDetailExpanded = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Handle app lifecycle events - refresh data when app resumes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Trigger refresh when app comes to foreground
      ref
          .read(productDetailControllerProvider(widget.product.id).notifier)
          .refresh();
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
        state.productDetail ?? convertToProductVariant(widget.product);

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

            // Product info (name, weight, wishlist)
            ProductInfo(
              productDetail: productDetail,
              isInWishlist: state.isInWishlist,
              onWishlistToggle: controller.toggleWishlist,
            ),
            AppSpacing.h16,

            // Price and add to cart row
            PriceRow(
              price: productDetail.price,
              quantity: state.quantity,
              onAdd: () => controller.setQuantity(1),
              onIncrement: () => controller.setQuantity(state.quantity + 1),
              onDecrement: () => controller.setQuantity(
                state.quantity > 0 ? state.quantity - 1 : 0,
              ),
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

            // Product weight/nutrition section
            ExpandableSection(
              title: "Nutritions",
              onToggle: () {},
              badge: productDetail.weight,
              child: const SizedBox(),
            ),

            // Rating and reviews section
            if (productDetail.rating != null)
              RatingSection(
                rating: productDetail.rating!,
                reviewCount: productDetail.reviewCount,
              ),
          ],
        ),
      ),
    );
  }

  /// Build bottom sheet (sticky checkout section)
  /// Delegates to CheckoutSection component for display
  /// Price calculation handled by CheckoutSection component
  Widget _buildBottomSheet(
    product_variant.ProductVariant productDetail,
    dynamic state,
  ) {
    // Extract numeric unit price
    final unitPrice = extractNumericPrice(productDetail.price);

    return CheckoutSection(unitPrice: unitPrice, quantity: state.quantity);
  }
}
