import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/application/providers/admin_phone_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../bottomnavbar/bottom_navbar.dart';
import '../../../cart/application/providers/checkout_line_provider.dart';
import '../../../category/presentation/components/widgets/review_bottom_sheet.dart';
import '../../application/providers/orders_provider.dart';
import '../../domain/entities/order_entity.dart';
import '../../infrastructure/data_sources/orders_api.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  bool _isActiveTab = true; // true = Active, false = Previous

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _fetchOrders());
  }

  void _fetchOrders() {
    if (_isActiveTab) {
      ref.read(ordersProvider.notifier).fetchActiveOrders();
    } else {
      ref.read(ordersProvider.notifier).fetchCompletedOrders();
    }
  }

  void _switchTab(bool isActive) {
    if (_isActiveTab != isActive) {
      setState(() => _isActiveTab = isActive);
      _fetchOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.black,
            size: 20.sp,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Your Orders',
          style: TextStyle(
            color: AppColors.black,
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Tab switcher
            _buildTabSwitcher(),
            SizedBox(height: 16.h),
            // Orders list
            Expanded(child: _buildBody(ordersState)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppColors.green60,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          // Previous tab
          Expanded(
            child: GestureDetector(
              onTap: () => _switchTab(false),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: !_isActiveTab ? AppColors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Previous',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: !_isActiveTab ? AppColors.white : AppColors.grey,
                  ),
                ),
              ),
            ),
          ),
          // Active tab
          Expanded(
            child: GestureDetector(
              onTap: () => _switchTab(true),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                decoration: BoxDecoration(
                  color: _isActiveTab ? AppColors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'Active',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: _isActiveTab ? AppColors.white : AppColors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(OrdersState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return _buildErrorState(state.errorMessage!);
    }

    if (state.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: AppColors.green,
      onRefresh: () async => _fetchOrders(),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: state.orders.length,
        itemBuilder: (context, index) => _OrderCard(
          order: state.orders[index],
          isActiveOrder: _isActiveTab,
          onReorder: () => _handleReorder(state.orders[index]),
          onCall: () => _handleCall(),
          onWriteReview: () => _handleWriteReview(state.orders[index]),
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64.sp, color: AppColors.grey),
            SizedBox(height: 16.h),
            Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              style: TextStyle(fontSize: 14.sp, color: AppColors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: _fetchOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(fontSize: 14.sp, color: AppColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80.sp, color: AppColors.grey),
          SizedBox(height: 16.h),
          Text(
            _isActiveTab ? 'No active orders' : 'No previous orders',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.black,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _isActiveTab
                ? 'Your active orders will appear here'
                : 'Your order history will appear here',
            style: TextStyle(fontSize: 14.sp, color: AppColors.grey),
          ),
        ],
      ),
    );
  }

  /// Reorders items from a previous order
  /// Fetches order lines from order-lines endpoint, adds items to cart with original quantities,
  /// then navigates to cart tab
  Future<void> _handleReorder(OrderEntity order) async {
    // Show loading indicator
    if (mounted) {
      AppSnackbar.info(context, 'Loading order items...');
    }

    try {
      // Fetch order lines from the order-lines endpoint
      final ordersApi = ref.read(ordersApiProvider);
      final orderLines = await ordersApi.getOrderLines(order.id.toString());

      if (orderLines.isEmpty) {
        if (mounted) {
          AppSnackbar.warning(context, 'This order has no items to reorder');
        }
        return;
      }

      // Show loading indicator for adding to cart
      if (mounted) {
        AppSnackbar.info(context, 'Adding items to cart...');
      }

      final checkoutLineNotifier = ref.read(
        checkoutLineControllerProvider.notifier,
      );

      int successCount = 0;
      int failedCount = 0;

      // Add each item from the order to cart with original quantities
      for (final orderLine in orderLines) {
        // Skip items with invalid product variant ID
        if (orderLine.productVariantId <= 0) {
          failedCount++;
          Logger.warning(
            'Skipping item with invalid variant ID: ${orderLine.productName} (${orderLine.productVariantId})',
          );
          continue;
        }

        try {
          // Add with original quantity from the order
          await checkoutLineNotifier.addToCart(
            productVariantId: orderLine.productVariantId,
            quantity: orderLine.quantity,
          );
          successCount++;
          Logger.info(
            'Added item to cart for reorder',
            data: {
              'product_variant_id': orderLine.productVariantId,
              'product_name': orderLine.productName,
              'quantity': orderLine.quantity,
            },
          );
        } catch (e) {
          // Item failed to add (likely out of stock or unavailable)
          failedCount++;
          Logger.error(
            'Failed to add item to cart: ${orderLine.productName} (variant: ${orderLine.productVariantId})',
            error: e,
          );
        }
      }

      // Show result to user and navigate to cart if successful
      if (mounted) {
        if (successCount > 0 && failedCount == 0) {
          // All items added successfully
          AppSnackbar.success(
            context,
            '$successCount item${successCount > 1 ? 's' : ''} added to cart',
          );
          // Navigate to cart tab (index 3 in bottom navbar)
          _navigateToCart();
        } else if (successCount > 0 && failedCount > 0) {
          // Some items added, some failed (likely out of stock)
          AppSnackbar.warning(
            context,
            '$successCount added, $failedCount unavailable',
          );
          // Still navigate to cart to show what was added
          _navigateToCart();
        } else {
          // All items failed
          AppSnackbar.error(
            context,
            'Items are currently unavailable. Please try again later.',
          );
        }
      }
    } catch (e) {
      Logger.error('Reorder failed', error: e);
      if (mounted) {
        AppSnackbar.error(context, 'Failed to reorder. Please try again.');
      }
    }
  }

  /// Navigate to cart tab in bottom navbar
  void _navigateToCart() {
    // Pop the orders screen to go back to the profile/main screen
    Navigator.of(context).pop();

    // Use the BottomNavigation global key to navigate to cart tab (index 3)
    BottomNavigation.globalKey.currentState?.navigateToTab(3);
  }

  /// Opens the phone dialer with the support number fetched from API
  /// Falls back to default number if API call fails
  /// Does not auto-start the call - just populates the dialer
  Future<void> _handleCall() async {
    // Fetch admin phone from API (with caching and fallback)
    final supportNumber = await ref
        .read(adminPhoneProvider.notifier)
        .getPhoneNumber();

    final Uri phoneUri = Uri(scheme: 'tel', path: supportNumber);

    try {
      // Check if the device can handle the tel: scheme
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        Logger.info('Phone dialer opened: $supportNumber');
      } else {
        // Device cannot handle phone calls (e.g., tablet without phone capability)
        if (mounted) {
          AppSnackbar.error(
            context,
            'Unable to open phone dialer. Please call $supportNumber manually.',
          );
        }
        Logger.warning('Cannot launch phone dialer: $supportNumber');
      }
    } catch (e) {
      Logger.error('Failed to open phone dialer', error: e);
      if (mounted) {
        AppSnackbar.error(
          context,
          'Failed to open phone dialer. Please try again.',
        );
      }
    }
  }

  /// Shows rating bottom sheet for the order
  /// Allows user to write a new review or update existing review
  Future<void> _handleWriteReview(OrderEntity order) async {
    // Only allow rating for delivered orders
    if (!order.isCompleted) {
      AppSnackbar.warning(
        context,
        'You can only rate orders that have been delivered',
      );
      return;
    }

    // Format delivery date (simple format)
    final deliveryDate = order.updatedAt ?? order.createdAt;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final formattedDate =
        '${deliveryDate.day} ${months[deliveryDate.month - 1]} ${deliveryDate.year}';

    // Show review bottom sheet
    final rating = await ReviewBottomSheet.show(
      context,
      orderTitle: 'Rate Your Order',
      orderSubtitle: 'Delivered on $formattedDate',
    );

    // Submit rating if user provided one
    if (rating != null && rating > 0) {
      await _submitOrderRating(order.id, rating);
    }
  }

  /// Submit order rating to backend
  Future<void> _submitOrderRating(int orderId, int stars) async {
    try {
      // Show loading
      if (mounted) {
        AppSnackbar.info(context, 'Submitting rating...');
      }

      await ref
          .read(ordersApiProvider)
          .submitOrderRating(orderId: orderId, stars: stars);

      Logger.info('Order rating submitted: $stars stars for order $orderId');

      // Show success message
      if (mounted) {
        AppSnackbar.success(context, 'Thank you for your rating!');
      }
    } catch (e) {
      Logger.error('Failed to submit order rating', error: e);

      // Show error message
      if (mounted) {
        final errorMessage = e.toString().contains('only rate your own')
            ? 'You can only rate your own completed orders'
            : 'Failed to submit rating. Please try again later.';

        AppSnackbar.error(context, errorMessage);
      }
    }
  }
}

class _OrderCard extends ConsumerStatefulWidget {
  final OrderEntity order;
  final bool isActiveOrder;
  final VoidCallback onReorder;
  final VoidCallback onCall;
  final VoidCallback onWriteReview;

  const _OrderCard({
    required this.order,
    required this.isActiveOrder,
    required this.onReorder,
    required this.onCall,
    required this.onWriteReview,
  });

  @override
  ConsumerState<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends ConsumerState<_OrderCard> {
  bool _isExpanded = false;
  int _rating = 0;
  bool _isEditingRating = false;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize rating from order data if it exists
    if (widget.order.rating != null) {
      _rating = widget.order.rating!.stars;
      _reviewController.text = widget.order.rating?.body ?? '';
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  String get _statusText {
    final status = widget.order.status.toLowerCase();
    switch (status) {
      case 'active':
      case 'shipped':
      case 'on_delivery':
      case 'out_for_delivery':
        return 'On Delivery';
      case 'pending':
      case 'processing':
        return 'Processing';
      case 'completed':
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return widget.order.status;
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[date.month - 1];
    final year = date.year;
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$day $month $year at $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    // Use orderlinesCount from API instead of orderLines.length
    final itemCount = widget.order.orderlinesCount;
    final firstProductImage = widget.order.orderLines.isNotEmpty
        ? widget.order.orderLines.first.productImage
        : null;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _isExpanded ? AppColors.green : AppColors.lightGreen,
          width: _isExpanded ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row - always visible
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  // Product image
                  Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      color: Colors.grey.shade100,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: firstProductImage != null
                        ? Image.network(
                            firstProductImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, s) => Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.grey,
                              size: 24.sp,
                            ),
                          )
                        : Icon(
                            Icons.shopping_bag_outlined,
                            color: AppColors.grey,
                            size: 24.sp,
                          ),
                  ),
                  SizedBox(width: 12.w),
                  // Order details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ID #${widget.order.id.toString().padLeft(6, '0')}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Text(
                              '$itemCount Item${itemCount > 1 ? 's' : ''}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.black,
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 8.w),
                              width: 4.w,
                              height: 4.w,
                              decoration: const BoxDecoration(
                                color: AppColors.black,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              _statusText,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.black,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Expand/collapse icon
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.grey,
                    size: 24.sp,
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          if (_isExpanded) ...[
            Padding(
              padding: EdgeInsets.all(16.w),
              child: widget.isActiveOrder
                  ? _buildActiveOrderContent()
                  : _buildPreviousOrderContent(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveOrderContent() {
    return Column(
      children: [
        // Date and price row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDate(widget.order.createdAt),
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.loaderGreen,
              ),
            ),
            Text(
              '₹${widget.order.totalAmount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.loaderGreen,
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        // Call button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onCall,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.green,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
              elevation: 0,
            ),
            child: Text(
              'Call',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviousOrderContent() {
    return Column(
      children: [
        // Rating section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Star rating - interactive
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = index + 1;
                      _isEditingRating = true;
                    });
                  },
                  child: Padding(
                    padding: EdgeInsets.only(right: 4.w),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: index < _rating ? Colors.amber : AppColors.grey,
                      size: 24.sp,
                    ),
                  ),
                );
              }),
            ),
            // Edit/Update review text
            GestureDetector(
              onTap: () {
                setState(() {
                  _isEditingRating = !_isEditingRating;
                });
              },
              child: Text(
                _isEditingRating
                    ? 'Cancel'
                    : (widget.order.rating != null
                          ? 'Edit Review'
                          : 'Write a review'),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: _isEditingRating ? AppColors.grey : AppColors.green,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Your Grocery Rating',
            style: TextStyle(fontSize: 10.sp, color: AppColors.grey),
          ),
        ),

        // Inline review editor (shown when editing)
        if (_isEditingRating) ...[
          SizedBox(height: 12.h),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your experience... (optional)',
              hintStyle: TextStyle(fontSize: 12.sp, color: AppColors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: AppColors.green),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(
                  color: AppColors.green.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: const BorderSide(color: AppColors.green),
              ),
              contentPadding: EdgeInsets.all(12.w),
            ),
            style: TextStyle(fontSize: 12.sp),
          ),
          SizedBox(height: 12.h),
          // Save rating button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _rating > 0 ? _saveRating : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                disabledBackgroundColor: AppColors.grey,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
                elevation: 0,
              ),
              child: Text(
                widget.order.rating != null ? 'Update Rating' : 'Submit Rating',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ] else if (widget.order.rating?.body != null &&
            widget.order.rating!.body!.isNotEmpty) ...[
          // Show existing review text when not editing
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.green60.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              widget.order.rating!.body!,
              style: TextStyle(fontSize: 12.sp, color: AppColors.black),
            ),
          ),
        ],

        SizedBox(height: 16.h),
        // Reorder button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: widget.onReorder,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.green),
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              'Reorder',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.green,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Save or update rating
  Future<void> _saveRating() async {
    if (_rating == 0) {
      return;
    }

    try {
      // Show loading
      if (mounted) {
        AppSnackbar.info(context, 'Submitting rating...');
      }

      // Submit rating with review text
      await ref
          .read(ordersApiProvider)
          .submitOrderRating(
            orderId: widget.order.id,
            stars: _rating,
            body: _reviewController.text.trim().isNotEmpty
                ? _reviewController.text.trim()
                : null,
            ratingId: widget.order.rating?.id,
          );

      Logger.info(
        'Order rating submitted: $_rating stars for order ${widget.order.id}',
      );

      // Close editing mode
      if (mounted) {
        setState(() {
          _isEditingRating = false;
        });

        // Show success message
        AppSnackbar.success(context, 'Thank you for your rating!');

        // Refresh orders to show updated rating
        ref.read(ordersProvider.notifier).fetchCompletedOrders();
      }
    } catch (e) {
      Logger.error('Failed to submit order rating', error: e);

      // Show error message
      if (mounted) {
        final errorMessage = e.toString().contains('only rate your own')
            ? 'You can only rate your own completed orders'
            : 'Failed to submit rating. Please try again later.';

        AppSnackbar.error(context, errorMessage);
      }
    }
  }
}
