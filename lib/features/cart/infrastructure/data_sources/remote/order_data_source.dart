import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/endpoints.dart';

/// Response model for checkout API
class CheckoutResponse {
  final String razorpayOrderId;
  final int amount; // Amount in paise
  final String currency;
  final String orderId;

  CheckoutResponse({
    required this.razorpayOrderId,
    required this.amount,
    required this.currency,
    required this.orderId,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    // Amount from API is in rupees (can be int or double)
    // Convert to paise (multiply by 100) for Razorpay
    final rawAmount = json['amount'];
    final amountInPaise = rawAmount is int
        ? rawAmount * 100
        : ((rawAmount as double) * 100).toInt();

    return CheckoutResponse(
      razorpayOrderId: json['razorpay_order_id'] as String,
      amount: amountInPaise,
      currency: json['currency'] as String? ?? 'INR',
      orderId: json['order_id']?.toString() ?? '',
    );
  }
}

/// Response model for payment verification API
class PaymentVerifyResponse {
  final bool success;
  final String message;
  final String? orderId;

  PaymentVerifyResponse({
    required this.success,
    required this.message,
    this.orderId,
  });

  factory PaymentVerifyResponse.fromJson(Map<String, dynamic> json) {
    return PaymentVerifyResponse(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      orderId: json['order_id']?.toString(),
    );
  }
}

/// Data source for order and payment related API calls
class OrderDataSource {
  final ApiClient _apiClient;

  OrderDataSource(this._apiClient);

  /// Apply coupon to checkout
  /// PATCH /api/order/checkouts/{checkout_id}/
  Future<void> applyCoupon({
    required int checkoutId,
    required int couponId,
  }) async {
    await _apiClient.patch(
      ApiEndpoints.applyCoupon(checkoutId),
      data: {'coupon': couponId},
    );
  }

  /// Initiate payment and get Razorpay order details
  Future<CheckoutResponse> initiatePayment({required int addressId}) async {
    final response = await _apiClient.post(
      ApiEndpoints.paymentInitiate,
      data: {'address_id': addressId},
    );

    developer.log('========== PAYMENT INITIATE RAW RESPONSE ==========');
    developer.log('Response: ${response.data}');
    developer.log('===================================================');

    return CheckoutResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// Verify Razorpay payment after successful payment
  Future<PaymentVerifyResponse> verifyPayment({
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.paymentVerify,
      data: {
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_signature': razorpaySignature,
      },
    );

    developer.log('========== PAYMENT VERIFY RAW RESPONSE ==========');
    developer.log('Response: ${response.data}');
    developer.log('=================================================');

    return PaymentVerifyResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}

/// Provider for OrderDataSource
final orderDataSourceProvider = Provider<OrderDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return OrderDataSource(apiClient);
});
