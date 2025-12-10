import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../app/theme/colors.dart';
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
          icon: Icon(Icons.arrow_back, color: AppColors.black, size: 24.sp),
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
      body: Column(
        children: [
          // Tab switcher
          _buildTabSwitcher(),
          SizedBox(height: 16.h),
          // Orders list
          Expanded(child: _buildBody(ordersState)),
        ],
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
      return const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      );
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

  void _handleReorder(OrderEntity order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reorder feature coming soon'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  void _handleCall() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calling support...'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  void _handleWriteReview(OrderEntity order) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Review feature coming soon'),
        backgroundColor: AppColors.green,
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
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
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _isExpanded = false;
  int _rating = 0;

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
    final itemCount = widget.order.orderLines.length;
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
                                color: AppColors.grey,
                              ),
                            ),
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: 8.w),
                              width: 4.w,
                              height: 4.w,
                              decoration: const BoxDecoration(
                                color: AppColors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            Text(
                              _statusText,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColors.grey,
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
            Divider(height: 1, color: Colors.grey.shade200),
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
            // Star rating
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
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
            // Write a review
            GestureDetector(
              onTap: widget.onWriteReview,
              child: Text(
                'Write a review',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.green,
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
}
