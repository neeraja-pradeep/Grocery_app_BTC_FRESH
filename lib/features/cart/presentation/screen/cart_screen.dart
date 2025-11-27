import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/widgets/app_text.dart';
import '../components/cart_item_card.dart';
import '../components/cart_summary.dart';
import '../components/minimum_order_warning.dart';
import 'checkout_screen.dart';
import 'delivery_screen.dart';

/// Cart Screen - Thin Coordinator
///
/// Displays shopping cart with:
/// - Tab navigation (Cart items, Checkout, Delivery)
/// - Minimum order warning
/// - Cart item cards
/// - Suggested products link
/// - Cart summary with total and checkout button
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock data for UI demonstration
  final List<Map<String, dynamic>> _mockCartItems = [
    {
      'id': '1',
      'name': 'Yellow Cherry Tomatoes 250g',
      'imageUrl': 'assets/images/cart_item1.png',
      'weight': '250g',
      'pricePerKg': '3,45',
      'quantity': 1,
      'stockBadge': '1,80',
    },
    {
      'id': '2',
      'name': 'Roma VF Tomatoes',
      'imageUrl': 'assets/images/cart_item2.png',
      'weight': '500g',
      'pricePerKg': '2,85',
      'quantity': 2,
      'stockBadge': '1,60',
    },
  ];

  final double _minimumOrderValue = 150.0;
  double _currentTotal = 125.50;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFA5D6A7),
      body: Column(
        children: [
          _buildGreenHeader(),
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

  Widget _buildGreenHeader() {
    return Container(
      height: MediaQuery.of(context).padding.top,
      color: const Color(0xFFA5D6A7),
    );
  }

  Widget _buildHeader() {
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
      padding: EdgeInsets.symmetric(horizontal: 20.w),
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
    return Container(
      color: Colors.white,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildCartItemsTabWithSummary(),
          CheckoutScreen(cartItems: _mockCartItems),
          const DeliveryScreen(),
        ],
      ),
    );
  }

  Widget _buildCartItemsTabWithSummary() {
    return Column(
      children: [
        Expanded(child: _buildCartItemsTab()),
        // Cart summary (sticky at bottom, only for cart items tab)
        CartSummary(
          totalWithoutTax: _currentTotal,
          onCheckout: _handleCheckout,
          meetsMinimumOrder: _currentTotal >= _minimumOrderValue,
          minimumOrderMessage: _currentTotal < _minimumOrderValue
              ? 'Add more items to meet the ${_minimumOrderValue.toStringAsFixed(0)} min order value'
              : null,
        ),
      ],
    );
  }

  Widget _buildCartItemsTab() {
    final meetsMinimum = _currentTotal >= _minimumOrderValue;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Minimum order warning
          if (!meetsMinimum)
            MinimumOrderWarning(minimumValue: _minimumOrderValue),

          // Cart items list
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _mockCartItems.length,
            itemBuilder: (context, index) {
              final item = _mockCartItems[index];
              return CartItemCard(
                imageUrl: item['imageUrl'] as String?,
                name: item['name'] as String,
                weight: item['weight'] as String,
                pricePerKg: item['pricePerKg'] as String,
                quantity: item['quantity'] as int,
                stockBadge: item['stockBadge'] as String,
                onIncrement: () => _handleIncrement(index),
                onDecrement: () => _handleDecrement(index),
                onRemove: () => _handleRemove(index),
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

  void _handleIncrement(int index) {
    setState(() {
      _mockCartItems[index]['quantity'] =
          (_mockCartItems[index]['quantity'] as int) + 1;
      _recalculateTotal();
    });
  }

  void _handleDecrement(int index) {
    setState(() {
      final currentQuantity = _mockCartItems[index]['quantity'] as int;
      if (currentQuantity > 1) {
        _mockCartItems[index]['quantity'] = currentQuantity - 1;
        _recalculateTotal();
      }
    });
  }

  void _handleRemove(int index) {
    setState(() {
      _mockCartItems.removeAt(index);
      _recalculateTotal();
    });
  }

  void _recalculateTotal() {
    // Simple mock calculation
    double total = 0;
    for (final item in _mockCartItems) {
      final price =
          double.tryParse(
            (item['pricePerKg'] as String).replaceAll(',', '.'),
          ) ??
          0;
      final quantity = item['quantity'] as int;
      total += price * quantity * 10; // Mock multiplier
    }
    _currentTotal = total;
  }

  void _handleViewSuggestedProducts() {
    // TODO: Navigate to suggested products
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navigate to suggested products')),
    );
  }

  void _handleCheckout() {
    if (_currentTotal >= _minimumOrderValue) {
      // TODO: Navigate to checkout
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Proceed to checkout')));
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
