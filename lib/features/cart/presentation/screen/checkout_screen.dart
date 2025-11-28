import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:grocery_app/app/theme/colors.dart';
import 'package:grocery_app/core/widgets/app_text.dart';
import 'package:grocery_app/features/cart/application/providers/address_providers.dart';
import '../components/address_sheet.dart';
import '../components/cart_item_card.dart';
import '../components/checkout_order_summary.dart';

/// Checkout screen - displays cart items and order summary with selected address
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, this.cartItems = const []});

  final List<Map<String, dynamic>> cartItems;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late List<Map<String, dynamic>> _checkoutItems;

  @override
  void initState() {
    super.initState();
    // Create a copy of cart items for checkout
    _checkoutItems = List<Map<String, dynamic>>.from(
      widget.cartItems.map((item) => Map<String, dynamic>.from(item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate order totals (mock calculation)
    final itemTotal = _calculateItemTotal();
    final discount = itemTotal * 0.1; // 10% mock discount
    final gst = (itemTotal - discount) * 0.18; // 18% GST
    final deliveryFee = 0.0; // Free delivery
    final grandTotal = itemTotal - discount + gst + deliveryFee;

    return Column(
      children: [
        // Main scrollable content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Cart items list with quantity controls
                if (_checkoutItems.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _checkoutItems.length,
                    itemBuilder: (context, index) {
                      final item = _checkoutItems[index];
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
                  )
                else
                  _buildEmptyCart(),

                // Extra padding for order summary
                SizedBox(height: 20.h),
              ],
            ),
          ),
        ),

        // Order summary with delivery address (sticky at bottom)
        CheckoutOrderSummary(
          itemTotal: itemTotal,
          discount: discount,
          gst: gst,
          deliveryFee: deliveryFee,
          grandTotal: grandTotal,
          onPlaceOrder: () => _handlePlaceOrder(context),
          deliveryAddressWidget: _buildDeliveryAddressSection(),
        ),
      ],
    );
  }

  Widget _buildDeliveryAddressSection() {
    // Watch selected address from provider
    final addressState = ref.watch(addressControllerProvider);
    final selectedAddress = addressState.selectedAddress;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: AppColors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Icon container
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.green60, // Background color
              // shape: BoxShape.circle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SvgPicture.asset(
              'assets/svgs/order/home.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                AppColors.couponGreen, // icon color on green bg
                BlendMode.srcIn,
              ),
            ),
          ),

          SizedBox(width: 8.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: selectedAddress != null
                      ? 'Delivering to: ${selectedAddress.addressType.toUpperCase()}'
                      : 'No address selected',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                SizedBox(height: 2.h),
                AppText(
                  text:
                      selectedAddress?.formattedAddress ??
                      'Please select a delivery address',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w400,
                  color: AppColors.grey,
                  maxLines: 1,
                ),
              ],
            ),
          ),

          SizedBox(width: 8.w),

          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddressSheet(),
              );
            },
            child: AppText(
              text: 'Change',
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.green100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 40.h),
      child: Column(
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 60.sp,
            color: AppColors.grey.withValues(alpha: 0.5),
          ),
          SizedBox(height: 16.h),
          AppText(
            text: 'No items in checkout',
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.grey,
          ),
        ],
      ),
    );
  }

  void _handleIncrement(int index) {
    setState(() {
      _checkoutItems[index]['quantity'] =
          (_checkoutItems[index]['quantity'] as int) + 1;
    });
  }

  void _handleDecrement(int index) {
    setState(() {
      final currentQuantity = _checkoutItems[index]['quantity'] as int;
      if (currentQuantity > 1) {
        _checkoutItems[index]['quantity'] = currentQuantity - 1;
      }
    });
  }

  void _handleRemove(int index) {
    setState(() {
      _checkoutItems.removeAt(index);
    });
  }

  double _calculateItemTotal() {
    double total = 0;
    for (final item in _checkoutItems) {
      final price =
          double.tryParse(
            (item['pricePerKg'] as String).replaceAll(',', '.'),
          ) ??
          0;
      final quantity = item['quantity'] as int;
      total += price * quantity * 10; // Mock multiplier
    }
    return total;
  }

  void _handlePlaceOrder(BuildContext context) {
    // TODO: Navigate to order confirmation
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Order placed successfully!')));
  }
}
