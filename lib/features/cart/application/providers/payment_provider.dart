import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../infrastructure/data_sources/remote/order_data_source.dart';
import '../../infrastructure/services/razorpay_service.dart';

/// Payment state for tracking payment flow
enum PaymentStatus {
  idle,
  applyingCoupon,
  creatingOrder,
  awaitingPayment,
  verifyingPayment,
  success,
  failed,
}

class PaymentState {
  final PaymentStatus status;
  final String? errorMessage;
  final String? orderId;

  const PaymentState({
    this.status = PaymentStatus.idle,
    this.errorMessage,
    this.orderId,
  });

  PaymentState copyWith({
    PaymentStatus? status,
    String? errorMessage,
    String? orderId,
  }) {
    return PaymentState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      orderId: orderId ?? this.orderId,
    );
  }

  bool get isLoading =>
      status == PaymentStatus.applyingCoupon ||
      status == PaymentStatus.creatingOrder ||
      status == PaymentStatus.verifyingPayment;
}

/// Controller for handling the complete payment flow
class PaymentController extends StateNotifier<PaymentState> {
  final OrderDataSource _orderDataSource;
  final RazorpayService _razorpayService;

  PaymentController({
    required OrderDataSource orderDataSource,
    required RazorpayService razorpayService,
  }) : _orderDataSource = orderDataSource,
       _razorpayService = razorpayService,
       super(const PaymentState()) {
    _razorpayService.init();
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    super.dispose();
  }

  /// Reset payment state
  void reset() {
    state = const PaymentState();
  }

  /// Initiate payment flow
  ///
  /// 1. If coupon applied, PATCH /api/order/checkouts/{checkout_id}/ with coupon
  /// 2. Call /api/order/payment/initiate/ to create order
  /// 3. Open Razorpay with returned order_id
  /// 4. On success, call /api/order/payment/verify/
  Future<void> initiatePayment({
    required int addressId,
    int? checkoutId,
    int? couponId,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    required void Function() onSuccess,
    required void Function(String error) onFailure,
  }) async {
    try {
      // Step 1: Apply coupon if provided
      if (couponId != null && checkoutId != null) {
        state = state.copyWith(status: PaymentStatus.applyingCoupon);
        developer.log('Applying coupon $couponId to checkout $checkoutId');

        await _orderDataSource.applyCoupon(
          checkoutId: checkoutId,
          couponId: couponId,
        );

        developer.log('Coupon applied successfully');
      }

      // Step 2: Initiate payment via API
      state = state.copyWith(status: PaymentStatus.creatingOrder);

      final checkoutResponse = await _orderDataSource.initiatePayment(
        addressId: addressId,
      );

      developer.log(
        'Checkout Response: Order ID: ${checkoutResponse.razorpayOrderId}',
      );
      developer.log('Amount: ${checkoutResponse.amount}');

      // Step 2: Open Razorpay payment
      state = state.copyWith(
        status: PaymentStatus.awaitingPayment,
        orderId: checkoutResponse.orderId,
      );

      _razorpayService.openCheckout(
        razorpayOrderId: checkoutResponse.razorpayOrderId,
        amount: checkoutResponse.amount,
        currency: checkoutResponse.currency,
        customerName: customerName,
        customerEmail: customerEmail,
        customerPhone: customerPhone,
        onComplete: (result) async {
          if (result.success) {
            // Step 3: Verify payment
            await _verifyPayment(
              razorpayPaymentId: result.paymentId!,
              razorpayOrderId: result.orderId!,
              razorpaySignature: result.signature!,
              onSuccess: onSuccess,
              onFailure: onFailure,
            );
          } else {
            state = state.copyWith(
              status: PaymentStatus.failed,
              errorMessage: result.errorMessage ?? 'Payment failed',
            );
            onFailure(result.errorMessage ?? 'Payment failed');
          }
        },
      );
    } catch (e) {
      developer.log('Payment Error: $e');
      state = state.copyWith(
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
      );
      onFailure(e.toString());
    }
  }

  Future<void> _verifyPayment({
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
    required void Function() onSuccess,
    required void Function(String error) onFailure,
  }) async {
    try {
      state = state.copyWith(status: PaymentStatus.verifyingPayment);

      // Log payment details for debugging
      developer.log('========== PAYMENT VERIFY REQUEST ==========');
      developer.log('razorpay_payment_id: $razorpayPaymentId');
      developer.log('razorpay_order_id: $razorpayOrderId');
      developer.log('razorpay_signature: $razorpaySignature');
      developer.log('=============================================');

      final verifyResponse = await _orderDataSource.verifyPayment(
        razorpayPaymentId: razorpayPaymentId,
        razorpayOrderId: razorpayOrderId,
        razorpaySignature: razorpaySignature,
      );

      if (verifyResponse.success) {
        state = state.copyWith(
          status: PaymentStatus.success,
          orderId: verifyResponse.orderId,
        );
        onSuccess();
      } else {
        state = state.copyWith(
          status: PaymentStatus.failed,
          errorMessage: verifyResponse.message,
        );
        onFailure(verifyResponse.message);
      }
    } catch (e) {
      developer.log('Verify Payment Error: $e');
      state = state.copyWith(
        status: PaymentStatus.failed,
        errorMessage: e.toString(),
      );
      onFailure(e.toString());
    }
  }
}

/// Provider for RazorpayService
final razorpayServiceProvider = Provider<RazorpayService>((ref) {
  final service = RazorpayService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for PaymentController
final paymentControllerProvider =
    StateNotifierProvider<PaymentController, PaymentState>((ref) {
      return PaymentController(
        orderDataSource: ref.watch(orderDataSourceProvider),
        razorpayService: ref.watch(razorpayServiceProvider),
      );
    });
