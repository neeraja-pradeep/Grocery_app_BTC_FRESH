import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/network/socket_models.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_text.dart';
import '../../../auth/application/providers/auth_provider.dart';
import '../../../auth/application/states/auth_state.dart';
import '../../application/providers/address_providers.dart';
import '../../application/providers/applied_coupon_provider.dart';
import '../../application/providers/checkout_line_provider.dart';
import '../../application/providers/payment_provider.dart';
import '../../../profile/application/providers/profile_provider.dart';
import '../../domain/entities/checkout_line.dart';
import '../../infrastructure/data_sources/remote/checkout_line_data_source.dart';
import '../../../category/application/providers/price_update_notifier.dart';
import '../../../category/application/providers/inventory_update_notifier.dart';
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

    // Watch socket inventory updates for real-time stock changes
    final inventoryUpdates = ref.watch(inventoryUpdateNotifierProvider);

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

                      // Check stock availability for increment button
                      final inventoryUpdate = inventoryUpdates.getUpdate(
                        line.productVariantId,
                      );
                      final currentStock = inventoryUpdate?.currentQuantity;
                      final canIncrement =
                          currentStock == null || currentStock > line.quantity;

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
                        onIncrement: canIncrement
                            ? () =>
                                  _handleIncrement(ref, line.id, line.quantity)
                            : null,
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

  Future<void> _handlePlaceOrder(BuildContext context, WidgetRef ref) async {
    final addressState = ref.read(addressControllerProvider);
    final selectedAddress = addressState.selectedAddress;

    // Validate address is selected
    if (selectedAddress == null) {
      AppSnackbar.warning(context, 'Please select a delivery address');
      return;
    }

    // Refresh cart to get latest data before payment
    AppSnackbar.info(context, 'Verifying cart...');
    try {
      await ref.read(checkoutLineControllerProvider.notifier).refresh();
    } catch (e) {
      if (context.mounted) {
        AppSnackbar.error(context, 'Failed to verify cart. Please try again.');
      }
      return;
    }

    // Validate cart is not empty after refresh
    final checkoutState = ref.read(checkoutLineControllerProvider);
    if (checkoutState.items.isEmpty) {
      if (context.mounted) {
        AppSnackbar.warning(context, 'Your cart is empty');
      }
      return;
    }

    // Validate all items have sufficient stock
    final inventoryUpdates = ref.read(inventoryUpdateNotifierProvider);
    for (final item in checkoutState.items) {
      final inventoryUpdate = inventoryUpdates.getUpdate(item.productVariantId);
      // Get current stock from socket update or fallback to API data
      final currentStock =
          inventoryUpdate?.currentQuantity ??
          item.productVariantDetails.currentQuantity;

      if (currentStock <= 0) {
        if (context.mounted) {
          AppSnackbar.warning(
            context,
            '${item.productVariantDetails.name} is out of stock. Please remove it from cart.',
          );
        }
        return;
      }

      if (currentStock < item.quantity) {
        if (context.mounted) {
          AppSnackbar.warning(
            context,
            '${item.productVariantDetails.name} has only $currentStock units available. Please update quantity.',
          );
        }
        return;
      }
    }

    // Get checkout ID from first cart item
    final checkoutId = checkoutState.items.first.checkout;

    // Get applied coupon ID if any
    final appliedCouponState = ref.read(appliedCouponProvider);
    final couponId = appliedCouponState.appliedCoupon?.id;

    // Get user profile for email and phone
    final profileState = ref.read(profileControllerProvider);
    final profile = profileState.profile;

    // Get phone from profile, fallback to auth user's phone
    String? customerPhone = profile?.mobileNumber;
    String? customerEmail = profile?.email;

    // Fallback: get from auth state if profile doesn't have phone
    if (customerPhone == null || customerPhone.isEmpty) {
      final authState = ref.read(authProvider);
      if (authState is Authenticated) {
        customerPhone = authState.user.phoneNumber;
        // Also get email if not available from profile
        if (customerEmail == null || customerEmail.isEmpty) {
          customerEmail = authState.user.email;
        }
      }
    }

    // Initiate payment
    ref
        .read(paymentControllerProvider.notifier)
        .initiatePayment(
          addressId: selectedAddress.id,
          checkoutId: checkoutId,
          couponId: couponId,
          customerName: selectedAddress.fullName,
          customerEmail: customerEmail,
          customerPhone: customerPhone,
          onSuccess: () {
            // Refresh cart to clear it after successful payment
            ref.read(checkoutLineControllerProvider.notifier).refresh();
            // Clear applied coupon after successful payment
            ref.read(appliedCouponProvider.notifier).removeCoupon();
            // Navigate to order confirmation screen using go_router
            if (context.mounted) {
              context.go('/order-success');
            }
          },
          onFailure: (error) {
            // Navigate to failed order screen using go_router
            if (context.mounted) {
              // Check if it's a reservation expired error
              final isReservationExpired =
                  error.toLowerCase().contains('reservation expired') ||
                  error.toLowerCase().contains('reservation not found');

              context.push(
                '/order-failed',
                extra: {
                  'error': error,
                  'isReservationExpired': isReservationExpired,
                },
              );
            }
          },
        );
  }
}
