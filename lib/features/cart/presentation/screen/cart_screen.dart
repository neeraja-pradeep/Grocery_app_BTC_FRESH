import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/network/socket_provider.dart';
import '../../../bottomnavbar/bottom_navbar.dart';
import '../../../../core/network/socket_service.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text.dart';
import '../../application/providers/checkout_line_provider.dart';
import '../../domain/entities/checkout_line.dart';
import '../../infrastructure/data_sources/remote/checkout_line_data_source.dart';
import '../../../../core/network/socket_models.dart';
import '../../../category/application/providers/inventory_update_notifier.dart';
import '../../../category/application/providers/price_update_notifier.dart';
import '../components/cart_app_bar.dart';
import '../components/cart_item_card.dart';
import '../components/cart_summary.dart';
import '../components/minimum_order_warning.dart';
import 'checkout_screen.dart';

/// Cart Screen - Displays shopping cart with real API data
///
/// Features:
/// - Tab navigation (Cart items, Checkout)
/// - Real-time cart data with 30-second polling
/// - Minimum order warning
/// - Quantity adjustment (increment/decrement with PATCH)
/// - Swipe-to-delete items (DELETE)
/// - Cart summary with total and checkout button
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  final double _minimumOrderValue = 150.0;
  final Set<int> _joinedRooms = {};

  // CACHE the socket service here so we don't call ref.read(...) in dispose
  late final SocketService socketService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addObserver(this);

    // cache socket service (safe to call ref.read in initState)
    socketService = ref.read(socketServiceProvider);

    // Join socket rooms for cart items after first frame
    // NOTE: We do NOT call _activateCartPolling() here because:
    // - With IndexedStack, CartScreen is mounted immediately even if user is on another tab
    // - Polling activation is handled by PollingTabController when user switches to Cart tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _joinCartItemRooms();

      // Handle route arguments to navigate to specific tab
      // e.g., from product details "Checkout" button which passes {'tab': 1}
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        final tabIndex = args['tab'] as int?;
        if (tabIndex != null && tabIndex >= 0 && tabIndex < 2) {
          _tabController.animateTo(tabIndex);
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // use cached socketService; avoid using ref.read here
    _leaveAllRooms();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-join socket rooms when app comes to foreground
      // NOTE: Polling is resumed by PollingManager.resumeActiveFeaturePolling()
      // which is called from BottomNavigation, not here
      _joinCartItemRooms();
    } else if (state == AppLifecycleState.paused) {
      // Leave rooms when app goes to background
      _leaveAllRooms();
    }
  }

  /// Join socket rooms for all cart items to receive real-time price updates
  void _joinCartItemRooms() {
    final checkoutState = ref.read(checkoutLineControllerProvider);
    final socketService = ref.read(socketServiceProvider);

    for (final item in checkoutState.items) {
      final variantId = item.productVariantId;
      if (!_joinedRooms.contains(variantId)) {
        socketService.joinVariantRoom(variantId);
        _joinedRooms.add(variantId);
      }
    }
  }

  /// Leave all joined socket rooms
  void _leaveAllRooms() {
    // guard in case called after widget unmounted
    if (!mounted) {
      _joinedRooms.clear();
      return;
    }

    // use cached socketService instead of ref.read
    for (final variantId in _joinedRooms) {
      socketService.leaveVariantRoom(variantId);
    }
    _joinedRooms.clear();
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutLineControllerProvider);
    final isCartEmpty = checkoutState.isEmpty || checkoutState.items.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.green60,
      appBar: const CartAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: Colors.white,
                child: isCartEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          _buildHeader(),
                          _buildDivider(),
                          _buildTabBar(),
                          Expanded(child: _buildBody()),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state UI - shown when cart is empty
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/trolley.png', width: 120.w, height: 120.h),
          SizedBox(height: 24.h),
          AppText(
            text: 'Your cart is empty',
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.loaderGreen,
          ),
          SizedBox(height: 32.h),
          SizedBox(
            width: 230.w,
            height: 48.h,
            child: ElevatedButton(
              onPressed: () {
                // Switch to categories tab (index 1) using bottom nav global key
                BottomNavigation.globalKey.currentState?.navigateToTab(1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: AppText(
                text: 'Continue Shopping',
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final checkoutState = ref.watch(checkoutLineControllerProvider);
    final itemCount = checkoutState.totalItems;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      color: Colors.white,
      child: Row(
        children: [
          AppText(
            text: 'My Cart',
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.black,
          ),
          if (itemCount > 0) ...[
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: AppColors.green100,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: AppText(
                text: '$itemCount',
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: AppColors.grey.withValues(alpha: 0.2));
  }

  Widget _buildTabBar() {
    final tabs = ['Cart items', 'Checkout'];

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Base underline for all tabs (keeps inactive tabs lined)
          Row(
            children: List.generate(
              tabs.length,
              (_) => Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 6.w),
                  height: 3,
                  decoration: BoxDecoration(
                    color: AppColors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.green100,
            unselectedLabelColor: AppColors.grey,
            labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
            unselectedLabelStyle: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: UnderlineTabIndicator(
              borderSide: const BorderSide(color: AppColors.green100, width: 4),
              insets: EdgeInsets.symmetric(horizontal: 6.w),
            ),
            dividerColor: Colors.transparent,
            labelPadding: EdgeInsets.zero,
            tabs: tabs
                .map(
                  (title) => Tab(
                    height: 36.h,
                    child: Center(
                      child: AppText(
                        text: title,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final checkoutState = ref.watch(checkoutLineControllerProvider);
    final cartItems = checkoutState.items;

    // Convert to mock format for checkout screen compatibility
    final mockCartItems = cartItems
        .map(
          (line) => {
            'id': line.id.toString(),
            'name': line.productVariantDetails.name,
            'imageUrl': line.productVariantDetails.media.isNotEmpty
                ? line.productVariantDetails.media.first
                : null,
            'weight': line.productVariantDetails.weight,
            'pricePerKg': line.productVariantDetails.effectivePrice
                .toStringAsFixed(2),
            'quantity': line.quantity,
            'stockBadge': line.productVariantDetails.discountedPrice,
          },
        )
        .toList();

    return Container(
      color: Colors.white,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildCartItemsTabWithSummary(),
          CheckoutScreen(cartItems: mockCartItems),
        ],
      ),
    );
  }

  Widget _buildCartItemsTabWithSummary() {
    final checkoutState = ref.watch(checkoutLineControllerProvider);
    final priceUpdates = ref.watch(priceUpdateNotifierProvider);

    // Calculate total with real-time socket price updates
    final currentTotal = _calculateTotalWithSocketPrices(
      checkoutState.items,
      priceUpdates,
    );

    return Column(
      children: [
        Expanded(child: _buildCartItemsTab()),
        // Cart summary (sticky at bottom, only for cart items tab)
        CartSummary(
          totalWithoutTax: currentTotal,
          onCheckout: _handleCheckout,
          meetsMinimumOrder: currentTotal >= _minimumOrderValue,
          minimumOrderMessage: currentTotal < _minimumOrderValue
              ? 'Add more items to meet the ${_minimumOrderValue.toStringAsFixed(0)} min order value'
              : null,
        ),
      ],
    );
  }

  /// Calculate cart total using real-time socket prices when available
  double _calculateTotalWithSocketPrices(
    List<CheckoutLine> items,
    PriceUpdateState priceUpdates,
  ) {
    double total = 0.0;
    for (final item in items) {
      final variantId = item.productVariantId;
      final socketPriceUpdate = priceUpdates.getUpdate(variantId);
      final effectivePrice = _getEffectivePriceForItem(
        item.productVariantDetails.effectivePrice,
        socketPriceUpdate,
      );
      total += item.quantity * effectivePrice;
    }
    return total;
  }

  /// Get effective price for an item, using socket price if available
  double _getEffectivePriceForItem(
    double apiPrice,
    PriceUpdateEvent? socketPriceUpdate,
  ) {
    if (socketPriceUpdate != null) {
      // Prefer discounted price if available, otherwise use newPrice
      if (socketPriceUpdate.discountedPrice != null &&
          socketPriceUpdate.discountedPrice! > 0) {
        return socketPriceUpdate.discountedPrice!;
      }
      return socketPriceUpdate.newPrice;
    }
    return apiPrice;
  }

  Widget _buildCartItemsTab() {
    final checkoutState = ref.watch(checkoutLineControllerProvider);
    final priceUpdates = ref.watch(priceUpdateNotifierProvider);
    final inventoryUpdates = ref.watch(inventoryUpdateNotifierProvider);

    // Use socket-aware total for minimum order check
    final currentTotal = _calculateTotalWithSocketPrices(
      checkoutState.items,
      priceUpdates,
    );
    final meetsMinimum = currentTotal >= _minimumOrderValue;

    // Join rooms for any new cart items
    _joinCartItemRooms();

    // Handle loading state
    if (checkoutState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Handle error state
    if (checkoutState.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: AppColors.grey),
            SizedBox(height: 16.h),
            AppText(
              text: 'Failed to load cart',
              fontSize: 14.sp,
              color: AppColors.grey,
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: () =>
                  ref.read(checkoutLineControllerProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Empty state is now handled at top level in build method
    final cartItems = checkoutState.items;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Minimum order warning
          if (!meetsMinimum)
            MinimumOrderWarning(minimumValue: _minimumOrderValue),

          // Cart items list with tap-to-delete
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final line = cartItems[index];
              final product = line.productVariantDetails;

              // Get socket price update if available for this variant
              final socketPriceUpdate = priceUpdates.getUpdate(
                line.productVariantId,
              );
              final effectivePrice = _getEffectivePriceForItem(
                product.effectivePrice,
                socketPriceUpdate,
              );
              // Use socket original price if available, otherwise use API price
              final originalPrice =
                  socketPriceUpdate?.oldPrice?.toStringAsFixed(2) ??
                  product.price;
              // Check if has discount from socket or API
              final hasDiscount = socketPriceUpdate != null
                  ? (socketPriceUpdate.discountedPrice != null &&
                        socketPriceUpdate.discountedPrice! > 0)
                  : product.hasDiscount;

              // Get real-time inventory update to check stock
              final inventoryUpdate = inventoryUpdates.getUpdate(
                line.productVariantId,
              );
              final currentStock = inventoryUpdate?.currentQuantity;
              // If we have inventory data, check if in stock; otherwise assume in stock
              final canIncrement =
                  currentStock == null || currentStock > line.quantity;

              return GestureDetector(
                onLongPress: () => _showDeleteDialog(line.id, product.name),
                child: CartItemCard(
                  imageUrl: product.media.isNotEmpty
                      ? product.media.first
                      : null,
                  name: product.name,
                  weight: product.weight,
                  pricePerKg: effectivePrice.toStringAsFixed(2),
                  quantity: line.quantity,
                  originalPrice: originalPrice,
                  hasDiscount: hasDiscount,
                  discountPercentage: product.discountPercentage,
                  isProcessing: checkoutState.isLineProcessing(line.id),
                  onIncrement: canIncrement
                      ? () => _handleIncrement(line.id, line.quantity)
                      : null,
                  onDecrement: () => _handleDecrement(line.id, line.quantity),
                  onRemove: () => _showDeleteDialog(line.id, product.name),
                ),
              );
            },
          ),

          // View suggested products link
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h),
            child: GestureDetector(
              onTap: _handleViewSuggestedProducts,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppText(
                    text: 'View suggested products',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.green100,
                  ),
                  SizedBox(width: 4.w),
                  Icon(
                    Icons.arrow_forward,
                    color: AppColors.green100,
                    size: 16.sp,
                  ),
                ],
              ),
            ),
          ),

          // Extra padding for bottom sheet
          SizedBox(height: 100.h),
        ],
      ),
    );
  }

  Future<void> _handleIncrement(int lineId, int currentQuantity) async {
    try {
      // PATCH request with delta +1
      await ref
          .read(checkoutLineControllerProvider.notifier)
          .updateQuantity(lineId: lineId, delta: 1);
    } on InsufficientStockException catch (e) {
      if (mounted) {
        AppSnackbar.warning(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to update quantity');
      }
    }
  }

  Future<void> _handleDecrement(int lineId, int currentQuantity) async {
    // When quantity is 1, decrementing will delete the item (handled by controller)
    try {
      // PATCH request with delta -1
      await ref
          .read(checkoutLineControllerProvider.notifier)
          .updateQuantity(lineId: lineId, delta: -1);
    } on InsufficientStockException catch (e) {
      if (mounted) {
        AppSnackbar.warning(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        AppSnackbar.error(context, 'Failed to update quantity');
      }
    }
  }

  /// Show delete confirmation dialog
  Future<void> _showDeleteDialog(int lineId, String productName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Item'),
        content: Text('Remove "$productName" from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref
            .read(checkoutLineControllerProvider.notifier)
            .deleteCheckoutLine(lineId);

        if (mounted) {
          AppSnackbar.success(context, 'Item removed from cart');
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.error(context, 'Failed to remove item');
        }
      }
    }
  }

  void _handleViewSuggestedProducts() {
    AppSnackbar.info(context, 'Suggested products coming soon');
  }

  void _handleCheckout() {
    final currentTotal = ref.read(checkoutLineControllerProvider).totalAmount;

    if (currentTotal >= _minimumOrderValue) {
      // Switch to checkout tab
      _tabController.animateTo(1);
    } else {
      AppSnackbar.warning(
        context,
        'Add more items to meet ₹${_minimumOrderValue.toStringAsFixed(0)} minimum',
      );
    }
  }
}
