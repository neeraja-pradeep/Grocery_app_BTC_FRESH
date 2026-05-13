import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Razorpay configuration constants
class RazorpayConfig {
  static const String keyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_RZlZ38QcLdQOEK',
  );
}

/// Result of a Razorpay payment attempt
class RazorpayPaymentResult {
  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? errorCode;
  final String? errorMessage;

  RazorpayPaymentResult.success({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  }) : success = true,
       errorCode = null,
       errorMessage = null;

  RazorpayPaymentResult.failure({
    required this.errorCode,
    required this.errorMessage,
  }) : success = false,
       paymentId = null,
       orderId = null,
       signature = null;

  RazorpayPaymentResult.cancelled()
    : success = false,
      paymentId = null,
      orderId = null,
      signature = null,
      errorCode = 'CANCELLED',
      errorMessage = 'Payment was cancelled by user';
}

/// Service to handle Razorpay payment operations
class RazorpayService {
  Razorpay? _razorpay;
  void Function(RazorpayPaymentResult)? _onComplete;

  /// Initialize Razorpay instance
  void init() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Clean up Razorpay instance
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _onComplete = null;
  }

  /// Open Razorpay payment checkout
  ///
  /// [razorpayOrderId] - Order ID from backend checkout API
  /// [amount] - Amount in paise (e.g., 10000 for Rs 100)
  /// [currency] - Currency code (default: INR)
  /// [customerName] - Customer name for prefill
  /// [customerEmail] - Customer email for prefill
  /// [customerPhone] - Customer phone for prefill
  /// [description] - Payment description
  /// [onComplete] - Callback with payment result
  void openCheckout({
    required String razorpayOrderId,
    required int amount,
    String currency = 'INR',
    String? customerName,
    String? customerEmail,
    String? customerPhone,
    String description = 'Grocery Order Payment',
    required void Function(RazorpayPaymentResult) onComplete,
  }) {
    if (_razorpay == null) {
      init();
    }

    _onComplete = onComplete;

    // Format phone number - Razorpay expects 10-digit Indian number without +91 prefix
    String? formattedPhone = customerPhone;
    if (formattedPhone != null) {
      // Remove +91 or 91 prefix if present
      formattedPhone = formattedPhone.replaceAll(RegExp(r'^\+?91'), '');
      // Remove any spaces or dashes
      formattedPhone = formattedPhone.replaceAll(RegExp(r'[\s\-]'), '');
    }

    final options = <String, dynamic>{
      'key': RazorpayConfig.keyId,
      'amount': amount,
      'currency': currency,
      'order_id': razorpayOrderId,
      'name': 'Grocery App',
      'description': description,
      'prefill': {
        if (customerName != null) 'name': customerName,
        if (customerEmail != null) 'email': customerEmail,
        if (formattedPhone != null && formattedPhone.isNotEmpty)
          'contact': formattedPhone,
      },
      'theme': {
        'color': '#8BC34A', // Green theme matching app
      },
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      _onComplete?.call(
        RazorpayPaymentResult.failure(
          errorCode: 'OPEN_ERROR',
          errorMessage: 'Failed to open payment gateway: $e',
        ),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _onComplete?.call(
      RazorpayPaymentResult.success(
        paymentId: response.paymentId ?? '',
        orderId: response.orderId ?? '',
        signature: response.signature ?? '',
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    // Check if user cancelled
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      _onComplete?.call(RazorpayPaymentResult.cancelled());
    } else {
      _onComplete?.call(
        RazorpayPaymentResult.failure(
          errorCode: response.code?.toString() ?? 'UNKNOWN',
          errorMessage: response.message ?? 'Payment failed',
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // External wallet selected - payment will continue in wallet app
    // The success/failure will come through the respective handlers
  }
}
