import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/network/socket_models.dart';
import '../../../../core/network/socket_provider.dart';
import '../../../../core/polling/polling_manager.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../cart/application/providers/checkout_line_provider.dart';
import '../../../cart/infrastructure/data_sources/remote/checkout_line_data_source.dart';
import '../../../category/application/providers/inventory_update_notifier.dart';
import '../../../category/application/providers/price_update_notifier.dart';
import '../components/checkout_section/checkout_section.dart';
import '../components/price_row/price_row.dart';
import '../components/product_info/product_info.dart';
import '../components/rating_section/rating_section.dart';

import '../../application/providers/product_detail_providers.dart';
import '../../application/states/product_detail_state.dart';
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
  const ProductDetailsScreen({super.key, required this.variantId});

  final String variantId;

  @override
  ConsumerState<ProductDetailsScreen> createState() =>
      _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen>
    with WidgetsBindingObserver {
  /// UI State: Only track expandable section state
  /// This is UI-only state and doesn't need Riverpod
  bool _isProductDetailExpanded = true;

  /// Store previous active feature to restore when popping back
  String? _previousActiveFeature;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Join variant room on mount for real-time Socket.IO updates
    // and activate product_detail polling feature
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final socketService = ref.read(socketServiceProvider);
      final variantId = int.tryParse(widget.variantId) ?? 0;
      if (variantId > 0) {
        socketService.joinVariantRoom(variantId);
      }

      // Save previous feature ONLY if it's not already 'product_detail'
      // This handles nested product navigation correctly:
      // Categories → Product1 → Product2 → pop → pop → back to Categories
      final currentFeature = PollingManager.instance.activeFeature;
      if (currentFeature != 'product_detail') {
        _previousActiveFeature = currentFeature;
      }
      PollingManager.instance.setActiveFeature('product_detail');
    });
  }

  @override
  void dispose() {
    // Restore previous active feature when leaving product details
    // This reactivates category_products polling when going back to categories
    if (_previousActiveFeature != null) {
      PollingManager.instance.setActiveFeature(_previousActiveFeature!);
    }

    // Don't use ref in dispose() - it's invalid after widget disposal
    // Socket.IO will handle cleanup automatically via Riverpod's ref.onDispose
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Handle app lifecycle events - refresh data when app resumes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Trigger refresh when app comes to foreground
      ref
          .read(productDetailControllerProvider(widget.variantId).notifier)
          .refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch business logic state from Riverpod
    final state = ref.watch(productDetailControllerProvider(widget.variantId));

    // Watch real-time Socket.IO updates
    final priceUpdates = ref.watch(priceUpdateNotifierProvider);
    final inventoryUpdates = ref.watch(inventoryUpdateNotifierProvider);

    // Extract variant ID for Socket updates lookup
    final variantId = int.tryParse(widget.variantId) ?? 0;

    // Watch cart state to get current quantity in cart
    final cartState = ref.watch(checkoutLineControllerProvider);
    final cartItem = cartState.items.where(
      (item) => item.productVariantId == variantId,
    );
    final isInCart = cartItem.isNotEmpty;
    final cartQuantity = isInCart ? cartItem.first.quantity : 0;
    final cartLineId = isInCart ? cartItem.first.id : 0;

    // Get real-time price from Socket if available, otherwise use API price
    final socketPriceUpdate = variantId > 0
        ? priceUpdates.getUpdate(variantId)
        : null;
    final socketInventoryUpdate = variantId > 0
        ? inventoryUpdates.getUpdate(variantId)
        : null;

    // Require API data - no fallback to category data
    if (state.isLoading || state.status == ProductDetailStatus.initial) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.hasError || state.status == ProductDetailStatus.empty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: AppText(
            text: state.errorMessage ?? 'Failed to load product details',
            color: AppColors.grey,
          ),
        ),
      );
    }

    // At this point, we must have data
    if (state.productDetail == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final productDetail = state.productDetail!;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: _buildAppBar(context),
      body: _buildBody(
        productDetail: productDetail,
        state: state,
        socketPriceUpdate: socketPriceUpdate,
        socketInventoryUpdate: socketInventoryUpdate,
        variantId: variantId,
        cartQuantity: cartQuantity,
        cartLineId: cartLineId,
      ),
      bottomSheet: _buildBottomSheet(
        productDetail: productDetail,
        socketPriceUpdate: socketPriceUpdate,
        cartQuantity: cartQuantity,
      ),
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
  Widget _buildBody({
    required product_variant.ProductVariant productDetail,
    required ProductDetailState state,
    required PriceUpdateEvent? socketPriceUpdate,
    required InventoryUpdateEvent? socketInventoryUpdate,
    required int variantId,
    required int cartQuantity,
    required int cartLineId,
  }) {
    // Get controller for wishlist toggle
    final controller = ref.read(
      productDetailControllerProvider(widget.variantId).notifier,
    );

    // Calculate display price and original price based on discounted_price
    // If discountedPrice exists → it's the display price, price is strikethrough
    // If discountedPrice is null → price is the display price, no strikethrough
    final String displayPrice;
    final String? originalPrice;

    if (socketPriceUpdate != null) {
      // Use real-time Socket.IO price if available
      displayPrice = socketPriceUpdate.newPrice.toString();
      originalPrice = socketPriceUpdate.oldPrice?.toString();
    } else if (productDetail.discountedPrice != null &&
        productDetail.discountedPrice!.isNotEmpty) {
      // Has discount: discountedPrice is display, price is strikethrough
      displayPrice = productDetail.discountedPrice!;
      originalPrice = productDetail.price;
    } else {
      // No discount: price is display, no strikethrough
      displayPrice = productDetail.price;
      originalPrice = null;
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image section
            ProductImageSection(
              imageUrl: productDetail.imageUrl,
              media: productDetail.media,
            ),

            // Product info (name, weight, wishlist)
            ProductInfo(
              productDetail: productDetail,
              isInWishlist: state.isInWishlist,
              onWishlistToggle: controller.toggleWishlist,
            ),
            AppSpacing.h16,

            // Price and add to cart row - directly updates cart
            PriceRow(
              price: displayPrice,
              originalPrice: originalPrice,
              quantity: cartQuantity,
              onAdd: () => _handleAddToCart(variantId),
              onIncrement: () => _handleIncrement(cartLineId),
              onDecrement: () => _handleDecrement(cartLineId),
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
              title: 'Nutritions',
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
  Widget _buildBottomSheet({
    required product_variant.ProductVariant productDetail,
    required PriceUpdateEvent? socketPriceUpdate,
    required int cartQuantity,
  }) {
    // Calculate display price based on discounted_price logic
    final String displayPrice;

    if (socketPriceUpdate != null) {
      displayPrice = socketPriceUpdate.newPrice.toString();
    } else if (productDetail.discountedPrice != null &&
        productDetail.discountedPrice!.isNotEmpty) {
      displayPrice = productDetail.discountedPrice!;
    } else {
      displayPrice = productDetail.price;
    }

    final unitPrice = extractNumericPrice(displayPrice);

    return CheckoutSection(
      unitPrice: unitPrice,
      quantity: cartQuantity,
      onViewCart: _handleNavigateToCart,
      onCheckout: _handleNavigateToCheckout,
    );
  }

  /// Handle Add button tap - adds 1 item to cart
  Future<void> _handleAddToCart(int variantId) async {
    if (variantId <= 0) return;

    try {
      await ref
          .read(checkoutLineControllerProvider.notifier)
          .addToCart(productVariantId: variantId, quantity: 1);

      if (mounted) {
        AppSnackbar.success(context, 'Added to cart');
      }
    } on InsufficientStockException catch (e) {
      if (mounted) {
        AppSnackbar.warning(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to add to cart');
      }
    }
  }

  /// Handle increment button - increases quantity in cart
  Future<void> _handleIncrement(int cartLineId) async {
    if (cartLineId <= 0) return;

    try {
      await ref
          .read(checkoutLineControllerProvider.notifier)
          .updateQuantity(lineId: cartLineId, delta: 1);
    } on InsufficientStockException catch (e) {
      if (mounted) {
        AppSnackbar.warning(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to update cart');
      }
    }
  }

  /// Handle decrement button - decreases quantity in cart
  Future<void> _handleDecrement(int cartLineId) async {
    if (cartLineId <= 0) return;

    try {
      await ref
          .read(checkoutLineControllerProvider.notifier)
          .updateQuantity(lineId: cartLineId, delta: -1);
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to update cart');
      }
    }
  }

  /// Handle navigate to cart
  void _handleNavigateToCart() {
    Navigator.pushNamed(context, '/cart');
  }

  /// Handle navigate to checkout
  void _handleNavigateToCheckout() {
    Navigator.pushNamed(context, '/cart', arguments: {'tab': 1});
  }
}
