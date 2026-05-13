import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme/colors.dart';
import '../../../../core/application/providers/admin_phone_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../bottomnavbar/bottom_navbar.dart';
import '../../../cart/application/providers/checkout_line_provider.dart';
import '../../application/providers/orders_provider.dart';
import '../../domain/entities/order_entity.dart';

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
    // Only fetch if no data is loaded yet or if there was a prior error.
    // Pull-to-refresh is the user-initiated path for fresh data on revisit.
    Future.microtask(() {
      final state = ref.read(ordersProvider);
      if (state.orders.isEmpty || state.errorMessage != null) {
        _fetchOrders();
      }
    });
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
          onPressed: () => context.pop(),
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
            _buildTabSwitcher(),
            SizedBox(height: 16.h),
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

  /// Reorders items from a previous order.
  /// Fetches order lines then adds all valid items to the cart concurrently.
  Future<void> _handleReorder(OrderEntity order) async {
    if (mounted) {
      AppSnackbar.info(context, 'Adding items to cart...');
    }

    try {
      final orderLines = await ref
          .read(ordersProvider.notifier)
          .getOrderLines(order.id.toString());

      if (orderLines.isEmpty) {
        if (mounted) {
          AppSnackbar.warning(context, 'This order has no items to reorder');
        }
        return;
      }

      final checkoutLineNotifier = ref.read(
        checkoutLineControllerProvider.notifier,
      );

      final validLines = orderLines.where((l) => l.productVariantId > 0);

      // Add all valid items to the cart concurrently.
      final results = await Future.wait(
        validLines.map((line) async {
          try {
            await checkoutLineNotifier.addToCart(
              productVariantId: line.productVariantId,
              quantity: line.quantity,
            );
            return true;
          } catch (e) {
            Logger.error(
              'Failed to add item to cart: ${line.productName}',
              error: e,
            );
            return false;
          }
        }),
      );

      final skipped = orderLines.length - validLines.length;
      final successCount = results.where((r) => r).length;
      final failedCount = results.where((r) => !r).length + skipped;

      if (!mounted) return;

      if (successCount > 0 && failedCount == 0) {
        AppSnackbar.success(
          context,
          '$successCount item${successCount > 1 ? 's' : ''} added to cart',
        );
        _navigateToCart();
      } else if (successCount > 0 && failedCount > 0) {
        AppSnackbar.warning(
          context,
          '$successCount added, $failedCount unavailable',
        );
        _navigateToCart();
      } else {
        AppSnackbar.error(
          context,
          'Items are currently unavailable. Please try again later.',
        );
      }
    } catch (e) {
      Logger.error('Reorder failed', error: e);
      if (mounted) {
        AppSnackbar.error(context, 'Failed to reorder. Please try again.');
      }
    }
  }

  /// Navigate to cart tab in bottom navbar.
  /// Uses the bottom-nav global key since there is no standalone /cart route.
  void _navigateToCart() {
    context.pop();
    BottomNavigation.globalKey.currentState?.navigateToTab(3);
  }

  /// Opens the phone dialer with the support number fetched from API.
  Future<void> _handleCall() async {
    final supportNumber = await ref
        .read(adminPhoneProvider.notifier)
        .getPhoneNumber();

    final Uri phoneUri = Uri(scheme: 'tel', path: supportNumber);

    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        if (mounted) {
          AppSnackbar.error(
            context,
            'Unable to open phone dialer. Please call $supportNumber manually.',
          );
        }
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
}

class _OrderCard extends ConsumerStatefulWidget {
  final OrderEntity order;
  final bool isActiveOrder;
  final VoidCallback onReorder;
  final VoidCallback onCall;

  const _OrderCard({
    required this.order,
    required this.isActiveOrder,
    required this.onReorder,
    required this.onCall,
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final month = months[date.month - 1];
    final hour = date.hour > 12
        ? date.hour - 12
        : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day} $month ${date.year} at $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
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
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12.r),
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  // Product image — cached to avoid re-downloading on scroll.
                  Container(
                    width: 50.w,
                    height: 50.w,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                      color: Colors.grey.shade100,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: firstProductImage != null
                        ? CachedNetworkImage(
                            imageUrl: firstProductImage,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Icon(
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
                              widget.order.displayStatus,
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
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
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

  /// Save or update rating through the notifier (single entry point for rating submission).
  Future<void> _saveRating() async {
    if (_rating == 0) return;

    try {
      if (mounted) {
        AppSnackbar.info(context, 'Submitting rating...');
      }

      await ref.read(ordersProvider.notifier).submitRating(
            orderId: widget.order.id,
            stars: _rating,
            body: _reviewController.text.trim().isNotEmpty
                ? _reviewController.text.trim()
                : null,
            ratingId: widget.order.rating?.id,
          );

      if (mounted) {
        setState(() => _isEditingRating = false);
        AppSnackbar.success(context, 'Thank you for your rating!');
      }
    } catch (e) {
      Logger.error('Failed to submit order rating', error: e);
      if (mounted) {
        final msg = e.toString().contains('only rate your own')
            ? 'You can only rate your own completed orders'
            : 'Failed to submit rating. Please try again later.';
        AppSnackbar.error(context, msg);
      }
    }
  }
}
