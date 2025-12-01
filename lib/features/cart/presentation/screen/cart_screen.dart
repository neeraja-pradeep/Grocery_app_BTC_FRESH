import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/network/socket_provider.dart';
import 'package:grocery_app/core/network/socket_service.dart';
import 'package:grocery_app/core/polling/polling_manager.dart';
import 'package:grocery_app/core/widgets/app_text.dart';
import 'package:grocery_app/features/cart/application/providers/checkout_line_provider.dart';
import 'package:grocery_app/features/cart/infrastructure/data_sources/remote/checkout_line_data_source.dart';
import 'package:grocery_app/features/category/application/providers/price_update_notifier.dart';
import '../components/cart_app_bar.dart';
import '../components/cart_item_card.dart';
import '../components/cart_summary.dart';
import '../components/minimum_order_warning.dart';
import 'checkout_screen.dart';
import 'delivery_screen.dart';

/// Cart Screen - Displays shopping cart with real API data
///
/// Features:
/// - Tab navigation (Cart items, Checkout, Delivery)
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
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addObserver(this);

    // cache socket service (safe to call ref.read in initState)
    socketService = ref.read(socketServiceProvider);

    // Join socket rooms for cart items after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _joinCartItemRooms();
      _activateCartPolling();
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
      // Re-join rooms and resume polling when app comes to foreground
      _joinCartItemRooms();
      _activateCartPolling();
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

  /// Activate polling when cart screen becomes visible
  void _activateCartPolling() {
    // The CheckoutLineController already registers with PollingManager
    // We just need to activate it when the cart screen is visible
    PollingManager.instance.activatePoller(
      featureName: 'cart',
      resourceId: 'lines',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.green60,
      appBar: const CartAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.white,
              child: Column(
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
    final tabs = ['Cart items', 'Checkout', 'Delivery'];

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
          const DeliveryScreen(),
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
    List<dynamic> items,
    PriceUpdateState priceUpdates,
  ) {
    double total = 0.0;
    for (final item in items) {
      final variantId = item.productVariantId;
      final socketPriceUpdate = priceUpdates.getUpdate(variantId);

      // Use socket price if available, otherwise use API price
      double effectivePrice;
      if (socketPriceUpdate != null) {
        // Prefer discounted price if available, otherwise use newPrice
        if (socketPriceUpdate.discountedPrice != null &&
            socketPriceUpdate.discountedPrice! > 0) {
          effectivePrice = socketPriceUpdate.discountedPrice!;
        } else {
          effectivePrice = socketPriceUpdate.newPrice;
        }
      } else {
        effectivePrice = item.productVariantDetails.effectivePrice;
      }

      total += item.quantity * effectivePrice;
    }
    return total;
  }

  Widget _buildCartItemsTab() {
    final checkoutState = ref.watch(checkoutLineControllerProvider);
    final priceUpdates = ref.watch(priceUpdateNotifierProvider);

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

    // Handle empty state
    if (checkoutState.isEmpty || checkoutState.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 64.sp,
              color: AppColors.grey.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            AppText(
              text: 'Your cart is empty',
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.grey,
            ),
            SizedBox(height: 8.h),
            AppText(
              text: 'Add items to get started',
              fontSize: 14.sp,
              color: AppColors.grey.withValues(alpha: 0.7),
            ),
          ],
        ),
      );
    }

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

              return GestureDetector(
                onLongPress: () => _showDeleteDialog(line.id, product.name),
                child: CartItemCard(
                  imageUrl: product.media.isNotEmpty
                      ? product.media.first
                      : null,
                  name: product.name,
                  weight: product.weight,
                  pricePerKg: product.effectivePrice.toStringAsFixed(2),
                  quantity: line.quantity,
                  originalPrice: product.price,
                  hasDiscount: product.hasDiscount,
                  discountPercentage: product.discountPercentage,
                  onIncrement: () => _handleIncrement(line.id, line.quantity),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update quantity')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update quantity: $e')),
        );
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item removed from cart')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to remove item: $e')));
        }
      }
    }
  }

  void _handleViewSuggestedProducts() {
    // TODO: Navigate to suggested products
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to suggested products')),
    );
  }

  void _handleCheckout() {
    final currentTotal = ref.read(checkoutLineControllerProvider).totalAmount;

    if (currentTotal >= _minimumOrderValue) {
      // Switch to checkout tab
      _tabController.animateTo(1);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please add more items to meet minimum order value of ${_minimumOrderValue.toStringAsFixed(0)}',
          ),
        ),
      );
    }
  }
}
