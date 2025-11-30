import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/button_styles.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/widgets/app_text.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Sample order data - replace with actual data from API
  final List<OrderModel> _activeOrders = [
    OrderModel(
      orderId: '#001234',
      itemCount: 12,
      status: 'On Delivery',
      dateTime: '21 Oct 2025 at 4:45 PM',
      price: 25,
      imageUrl: 'assets/images/onion.png',
    ),
  ];

  final List<OrderModel> _previousOrders = [
    OrderModel(
      orderId: '#001234',
      itemCount: 12,
      status: 'Delivered',
      dateTime: '21 Oct 2025 at 4:45 PM',
      price: 25,
      imageUrl: 'assets/images/onion.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: AppColors.black, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
        title: AppText(
          text: 'Your Orders',
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.black,
        ),
      ),
      body: Column(
        children: [
          const Divider(),

          SizedBox(height: 16.h),

          // Tab Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Container(
              height: 48.h,
              decoration: BoxDecoration(
                color: AppColors.lightGreen,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: AppColors.white,
                unselectedLabelColor: AppColors.black,
                labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Previous'),
                  Tab(text: 'Active'),
                ],
              ),
            ),
          ),

          SizedBox(height: 16.h),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Previous Orders Tab
                _buildOrdersList(_previousOrders, isPrevious: true),

                // Active Orders Tab
                _buildOrdersList(_activeOrders, isPrevious: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> orders, {required bool isPrevious}) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 60.sp,
              color: AppColors.grey,
            ),
            SizedBox(height: 16.h),
            AppText(
              text: isPrevious ? 'No previous orders' : 'No active orders',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.grey,
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      itemCount: orders.length,
      separatorBuilder: (context, index) => SizedBox(height: 16.h),
      itemBuilder: (context, index) {
        return OrderCard(order: orders[index], isPrevious: isPrevious);
      },
    );
  }
}

class OrderCard extends StatefulWidget {
  final OrderModel order;
  final bool isPrevious;

  const OrderCard({super.key, required this.order, required this.isPrevious});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _isExpanded = true;
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Order Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                children: [
                  // Product Image
                  Container(
                    width: 50.w,
                    height: 50.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Image.asset(
                      widget.order.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.field,
                          child: Icon(
                            Icons.image_outlined,
                            color: AppColors.grey,
                            size: 24.sp,
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(width: 12.w),

                  // Order Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          text: 'Order ID ${widget.order.orderId}',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            AppText(
                              text: '${widget.order.itemCount} Items',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: AppColors.lightGrey,
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              width: 6.w,
                              height: 6.h,
                              decoration: BoxDecoration(
                                color: widget.isPrevious
                                    ? AppColors.green
                                    : AppColors.loaderGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            AppText(
                              text: widget.order.status,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                              color: AppColors.lightGrey,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Expand/Collapse Icon
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.black,
                    size: 24.sp,
                  ),
                ],
              ),
            ),
          ),

          // Expanded Content
          if (_isExpanded) ...[
            Divider(height: 1.h, color: AppColors.grey.withValues(alpha: 0.2)),

            if (widget.isPrevious)
              _buildPreviousOrderContent()
            else
              _buildActiveOrderContent(),
          ],
        ],
      ),
    );
  }

  Widget _buildActiveOrderContent() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Date and Price Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                text: widget.order.dateTime,
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.loaderGreen,
              ),
              AppText(
                text: '₹${widget.order.price}',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.loaderGreen,
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Call Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Call delivery person
              },
              style: ButtonStyles.greenButton,
              child: AppText(
                text: 'Call',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousOrderContent() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          // Rating Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Star Rating
              Row(
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = index + 1;
                      });
                    },
                    child: Padding(
                      padding: EdgeInsets.only(right: 4.w),
                      child: Icon(
                        index < _rating ? Icons.star : Icons.star_border,
                        color: index < _rating
                            ? Colors.amber
                            : AppColors.loaderGreen,
                        size: 24.sp,
                      ),
                    ),
                  );
                }),
              ),

              // Write a Review
              GestureDetector(
                onTap: () {
                  // Navigate to write review
                },
                child: AppText(
                  text: 'Write a review',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColors.loaderGreen,
                ),
              ),
            ],
          ),

          SizedBox(height: 8.h),

          // Your Grocery Rating Text
          Align(
            alignment: Alignment.centerLeft,
            child: AppText(
              text: 'Your Grocery Rating',
              fontSize: 12.sp,
              fontWeight: FontWeight.w400,
              color: AppColors.darkGrey,
            ),
          ),

          SizedBox(height: 16.h),

          // Reorder Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Reorder items
              },
              style: ButtonStyles.lightgreenButton,
              child: AppText(
                text: 'Reorder',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.loaderGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OrderModel {
  final String orderId;
  final int itemCount;
  final String status;
  final String dateTime;
  final double price;
  final String imageUrl;

  OrderModel({
    required this.orderId,
    required this.itemCount,
    required this.status,
    required this.dateTime,
    required this.price,
    required this.imageUrl,
  });
}
