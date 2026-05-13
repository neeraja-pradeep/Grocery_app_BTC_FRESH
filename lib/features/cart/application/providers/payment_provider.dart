import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/network_exceptions.dart';
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

// Sentinel used to distinguish "not passed" from null in copyWith.
const _unset = Object();

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
    Object? errorMessage = _unset,
    String? orderId,
  }) {
    return PaymentState(
      status: status ?? this.status,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      orderId: orderId ?? this.orderId,
    );
  }

  bool get isLoading =>
      status == PaymentStatus.applyingCoupon ||
      status == PaymentStatus.creatingOrder ||
      status == PaymentStatus.verifyingPayment;
}

/// Controller for handling the complete payment flow
class PaymentController extends Notifier<PaymentState> {
  late OrderDataSource _orderDataSource;
  late RazorpayService _razorpayService;

  @override
  PaymentState build() {
    _orderDataSource = ref.watch(orderDataSourceProvider);
    _razorpayService = ref.watch(razorpayServiceProvider);
    // keepAlive so payment state survives tab navigation during active payment
    ref.keepAlive();
    return const PaymentState();
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
        await _orderDataSource.applyCoupon(
          checkoutId: checkoutId,
          couponId: couponId,
        );
      }

      // Step 2: Initiate payment via API
      state = state.copyWith(status: PaymentStatus.creatingOrder);

      final checkoutResponse = await _orderDataSource.initiatePayment(
        addressId: addressId,
      );

      // Step 3: Open Razorpay payment
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
            // Step 4: Verify payment
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
      final errorMessage = e is NetworkException ? e.message : e.toString();
      state = state.copyWith(
        status: PaymentStatus.failed,
        errorMessage: errorMessage,
      );
      onFailure(errorMessage);
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
      String errorMessage = 'Payment verification failed';

      if (e is NetworkException) {
        errorMessage = e.message;
      } else {
        final errorStr = e.toString();
        if (errorStr.contains('Reservation expired') ||
            errorStr.contains('not found')) {
          errorMessage = 'Reservation expired or not found';
        } else if (errorStr.contains('signature')) {
          errorMessage = 'Payment signature verification failed';
        } else if (errorStr.contains('Amount mismatch')) {
          errorMessage = 'Amount mismatch';
        }
      }

      state = state.copyWith(
        status: PaymentStatus.failed,
        errorMessage: errorMessage,
      );
      onFailure(errorMessage);
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
    NotifierProvider<PaymentController, PaymentState>(PaymentController.new);
