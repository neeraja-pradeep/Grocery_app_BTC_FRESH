import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/network/socket_models.dart';
import '../../../../core/widgets/app_text.dart';
import '../../application/providers/address_providers.dart';
import '../../application/providers/applied_coupon_provider.dart';
import '../../application/providers/checkout_line_provider.dart';
import '../../application/providers/payment_provider.dart';
import '../../domain/entities/checkout_line.dart';
import '../../infrastructure/data_sources/remote/checkout_line_data_source.dart';
import '../../../bottomnavbar/bottom_navbar.dart';
import '../../../category/application/providers/price_update_notifier.dart';
import '../components/address_sheet.dart';
import '../components/cart_item_card.dart';
import '../components/checkout_order_summary.dart';

/// Checkout screen - displays cart items and order summary with selected address
/// Now uses checkoutLineControllerProvider directly for real-time sync
class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key, this.cartItems = const []});

  // Keep for backward compatibility but not used anymore
  final List<Map<String, dynamic>> cartItems;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch cart state directly from provider
    final checkoutState = ref.watch(checkoutLineControllerProvider);
    final cartItems = checkoutState.items;

    // Watch socket price updates for real-time price changes
    final priceUpdates = ref.watch(priceUpdateNotifierProvider);

    // Watch applied coupon
    final appliedCouponState = ref.watch(appliedCouponProvider);

    // Calculate order totals with socket prices
    final itemTotal = _calculateTotalWithSocketPrices(cartItems, priceUpdates);

    // Calculate discount from applied coupon (or 0 if no coupon)
    final discount = appliedCouponState.hasCoupon
        ? ref.read(appliedCouponProvider.notifier).calculateDiscount(itemTotal)
        : 0.0;

    // GST calculation (18% on amount after discount)
    final gst = (itemTotal - discount) * 0.18;
    const deliveryFee = 0.0; // Free delivery
    final grandTotal = itemTotal - discount + gst + deliveryFee;

    return Column(
      children: [
        // Main scrollable content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Cart items list with quantity controls
                if (cartItems.isNotEmpty)
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

                      return CartItemCard(
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
                        onIncrement: () =>
                            _handleIncrement(ref, line.id, line.quantity),
                        onDecrement: () =>
                            _handleDecrement(ref, line.id, line.quantity),
                        onRemove: () =>
                            _handleRemove(context, ref, line.id, product.name),
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
          appliedCoupon: appliedCouponState.appliedCoupon,
          onPlaceOrder: () => _handlePlaceOrder(context, ref),
          deliveryAddressWidget: _buildDeliveryAddressSection(context, ref),
        ),
      ],
    );
  }

  Widget _buildDeliveryAddressSection(BuildContext context, WidgetRef ref) {
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
              color: AppColors.green60,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SvgPicture.asset(
              'assets/svgs/order/home.svg',
              width: 20,
              height: 20,
              colorFilter: const ColorFilter.mode(
                AppColors.couponGreen,
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

  Future<void> _handleIncrement(
    WidgetRef ref,
    int lineId,
    int currentQuantity,
  ) async {
    try {
      await ref
          .read(checkoutLineControllerProvider.notifier)
          .updateQuantity(lineId: lineId, delta: 1);
    } on InsufficientStockException {
      // Stock error handled by provider
    } catch (_) {
      // Error handled by provider
    }
  }

  Future<void> _handleDecrement(
    WidgetRef ref,
    int lineId,
    int currentQuantity,
  ) async {
    try {
      await ref
          .read(checkoutLineControllerProvider.notifier)
          .updateQuantity(lineId: lineId, delta: -1);
    } on InsufficientStockException {
      // Stock error handled by provider
    } catch (_) {
      // Error handled by provider
    }
  }

  Future<void> _handleRemove(
    BuildContext context,
    WidgetRef ref,
    int lineId,
    String productName,
  ) async {
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

    if (confirmed == true) {
      try {
        await ref
            .read(checkoutLineControllerProvider.notifier)
            .deleteCheckoutLine(lineId);
      } catch (_) {
        // Error handled by provider
      }
    }
  }

  void _handlePlaceOrder(BuildContext context, WidgetRef ref) {
    final addressState = ref.read(addressControllerProvider);
    final selectedAddress = addressState.selectedAddress;

    // Validate address is selected
    if (selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a delivery address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate cart is not empty
    final checkoutState = ref.read(checkoutLineControllerProvider);
    if (checkoutState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get checkout ID from first cart item
    final checkoutId = checkoutState.items.first.checkout;

    // Get applied coupon ID if any
    final appliedCouponState = ref.read(appliedCouponProvider);
    final couponId = appliedCouponState.appliedCoupon?.id;

    // Initiate payment
    ref
        .read(paymentControllerProvider.notifier)
        .initiatePayment(
          addressId: selectedAddress.id,
          checkoutId: checkoutId,
          couponId: couponId,
          customerName: selectedAddress.fullName,
          onSuccess: () {
            // Payment successful - show success and navigate
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment successful! Order placed.'),
                backgroundColor: Colors.green,
              ),
            );
            // Clear applied coupon after successful payment
            ref.read(appliedCouponProvider.notifier).removeCoupon();
            // Navigate to order confirmation
            BottomNavigation.globalKey.currentState
                ?.navigateToCategoryAndShowReview();
          },
          onFailure: (error) {
            // Payment failed - show error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Payment failed: $error'),
                backgroundColor: Colors.red,
              ),
            );
          },
        );
  }
}
