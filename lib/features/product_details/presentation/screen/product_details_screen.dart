import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/network/socket_models.dart';
import '../../../../core/network/socket_provider.dart';
import '../../../../core/polling/polling_manager.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../auth/application/states/auth_state.dart';
import '../../../cart/application/providers/checkout_line_provider.dart';
import '../../../cart/infrastructure/data_sources/remote/checkout_line_data_source.dart';
import '../../../category/application/providers/inventory_update_notifier.dart';
import '../../../category/application/providers/price_update_notifier.dart';
import '../../../orders/application/providers/orders_provider.dart';
import '../../../orders/infrastructure/data_sources/orders_api.dart';
import '../../../wishlist/application/providers/wishlist_provider.dart';
import '../../../bottomnavbar/bottom_navbar.dart';
import '../components/checkout_section/checkout_section.dart';
import '../components/price_row/price_row.dart';
import '../components/product_info/product_info.dart';
import '../components/rating_section/rating_section.dart';

import '../../application/providers/product_detail_providers.dart';
import '../../application/providers/product_order_provider.dart';
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

      // Fetch completed orders for rating functionality
      // Only fetch if user is authenticated (not in guest mode)
      final authState = ref.read(authProvider);
      if (authState is! GuestMode) {
        ref.read(ordersProvider.notifier).fetchCompletedOrders();
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
        backgroundColor: AppColors.white,
        body: _buildErrorView(
          context,
          state.errorMessage ?? 'Failed to load product details',
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
    // Check wishlist status from wishlist provider
    final isInWishlist = ref.watch(isInWishlistProvider(widget.variantId));

    // Stock status: prioritize Socket.IO real-time update, fallback to API data
    final currentQuantity =
        socketInventoryUpdate?.currentQuantity ?? productDetail.currentQuantity;
    final inStock = currentQuantity > 0;
    final quantity = currentQuantity;

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
            // Back button
            Padding(
              padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
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

            // Product image section
            ProductImageSection(
              imageUrl: productDetail.imageUrl,
              media: productDetail.media,
            ),

            // Product info (name, weight, wishlist)
            ProductInfo(
              productDetail: productDetail,
              isInWishlist: isInWishlist,
              onWishlistToggle: _handleWishlistToggle,
            ),

            // Stock status indicator - only show if low stock or out of stock
            if (!inStock || quantity <= 10) ...[
              AppSpacing.h8,
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: inStock
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: inStock
                        ? Colors.orange.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      inStock ? Icons.warning : Icons.cancel,
                      color: inStock ? Colors.orange : Colors.red,
                      size: 18.sp,
                    ),
                    SizedBox(width: 6.w),
                    AppText(
                      text: inStock ? 'Only $quantity left' : 'Out of Stock',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: inStock
                          ? Colors.orange.shade700
                          : Colors.red.shade700,
                    ),
                  ],
                ),
              ),
            ],

            AppSpacing.h16,

            // Price and add to cart row - directly updates cart
            PriceRow(
              price: displayPrice,
              originalPrice: originalPrice,
              quantity: cartQuantity,
              onAdd: () => _handleAddToCart(variantId, inStock),
              onIncrement: () => _handleIncrement(cartLineId),
              onDecrement: () => _handleDecrement(cartLineId),
              isEnabled: inStock,
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
              Consumer(
                builder: (context, ref, child) {
                  // Check if user is in guest mode
                  final authState = ref.watch(authProvider);
                  final isGuest = authState is GuestMode;

                  // For guests: show rating but disable expansion
                  if (isGuest) {
                    return RatingSection(
                      rating: productDetail.rating!,
                      reviewCount: productDetail.reviewCount,
                      allowExpansion: false,
                    );
                  }

                  // Check if user has a completed order with this product
                  final completedOrder = ref.watch(
                    productCompletedOrderProvider(variantId),
                  );

                  return RatingSection(
                    rating: productDetail.rating!,
                    reviewCount: productDetail.reviewCount,
                    orderId: completedOrder?.orderId,
                    deliveryDate: completedOrder?.deliveryDate,
                    onRatingSubmit: (rating, orderId) =>
                        _handleRatingSubmit(rating, orderId),
                  );
                },
              ),

            // Add bottom padding for bottom sheet
            SizedBox(height: 100.h),
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
  Future<void> _handleAddToCart(int variantId, bool inStock) async {
    if (variantId <= 0) return;

    // Check if product is in stock before adding
    if (!inStock) {
      if (mounted) {
        AppSnackbar.warning(context, 'This product is out of stock');
      }
      return;
    }

    // Block guests from adding to cart
    final authState = ref.read(authProvider);
    final isGuest = authState is GuestMode;

    if (isGuest) {
      AppSnackbar.info(context, 'Please login to add items to cart');
      return;
    }

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

  /// Handle wishlist toggle
  Future<bool> _handleWishlistToggle() async {
    // Check if user is in guest mode
    final authState = ref.read(authProvider);
    final isGuest = authState is GuestMode;

    if (isGuest) {
      return false; // Return false to show login message in ProductInfo
    }

    try {
      // Check current state BEFORE toggling to show correct message
      final wasInWishlist = ref.read(isInWishlistProvider(widget.variantId));

      Logger.info(
        'Toggling wishlist for variant ${widget.variantId}: wasInWishlist=$wasInWishlist',
      );

      // Use wishlist provider to toggle wishlist
      final success = await ref
          .read(wishlistProvider.notifier)
          .toggleWishlist(widget.variantId);

      Logger.info('Toggle wishlist result: success=$success');

      if (mounted && success) {
        // Show message based on what action was performed
        final message = wasInWishlist
            ? 'Removed from wishlist'
            : 'Added to wishlist';
        Logger.info('Showing message: $message');
        AppSnackbar.success(context, message);
      }

      return success;
    } catch (e) {
      Logger.error('Failed to toggle wishlist: $e', error: e);
      if (mounted) {
        AppSnackbar.error(context, 'Failed to update wishlist');
      }
      return false;
    }
  }

  /// Handle navigate to cart
  void _handleNavigateToCart() {
    context.push('/cart');
  }

  /// Handle navigate to checkout
  void _handleNavigateToCheckout() {
    // Navigate to home route first (to ensure navbar is visible)
    context.go('/home');
    // Then switch to cart tab (index 3)
    BottomNavigation.globalKey.currentState?.navigateToTab(3);
  }

  /// Handle rating submission
  Future<void> _handleRatingSubmit(int rating, int orderId) async {
    Logger.info('Rating submitted: $rating stars for order $orderId');

    try {
      // Submit rating via API
      await ref
          .read(ordersApiProvider)
          .submitOrderRating(orderId: orderId, stars: rating);

      if (mounted) {
        AppSnackbar.success(context, 'Thank you for your rating!');
      }
    } catch (e) {
      Logger.error('Failed to submit rating: $e', error: e);
      if (mounted) {
        final errorMessage = e.toString().contains('403')
            ? 'You can only rate your own completed orders'
            : 'Failed to submit rating. Please try again.';
        AppSnackbar.error(context, errorMessage);
      }
    }
  }

  /// Build error view with user-friendly message
  Widget _buildErrorView(BuildContext context, String errorMessage) {
    // Log the error for debugging
    Logger.error('Product details error: $errorMessage', error: errorMessage);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 48.sp,
                color: Colors.red.shade400,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'Product not available',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              _getUserFriendlyErrorMessage(errorMessage),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Logger.info('User tapped retry on product details error');
                    ref
                        .read(
                          productDetailControllerProvider(
                            widget.variantId,
                          ).notifier,
                        )
                        .refresh();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  icon: Icon(Icons.refresh, size: 20.sp),
                  label: const Text('Try Again'),
                ),
                SizedBox(width: 12.w),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade300),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 12.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                  icon: Icon(Icons.arrow_back, size: 20.sp),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Convert error messages to user-friendly text
  String _getUserFriendlyErrorMessage(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();

    if (lowerError.contains('network') ||
        lowerError.contains('internet') ||
        lowerError.contains('connection')) {
      return 'No internet connection. Please check your network and try again.';
    } else if (lowerError.contains('timeout') ||
        lowerError.contains('timed out')) {
      return 'Request timed out. Please check your connection and try again.';
    } else if (lowerError.contains('server') ||
        lowerError.contains('500') ||
        lowerError.contains('502') ||
        lowerError.contains('503')) {
      return 'Unable to connect to server. Please try again later.';
    } else if (lowerError.contains('not found') || lowerError.contains('404')) {
      return 'This product is no longer available.';
    } else if (lowerError.contains('unauthorized') ||
        lowerError.contains('401')) {
      return 'Please log in to view product details.';
    } else {
      return 'Unable to load product details. Please try again.';
    }
  }
}
