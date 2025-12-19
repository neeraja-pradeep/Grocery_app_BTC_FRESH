import '../config/app_config.dart';

/// Centralized API endpoint configuration
class ApiEndpoints {
  const ApiEndpoints._();

  /// Base URL for all API requests
  /// Now uses centralized AppConfig
  static String get baseUrl => AppConfig.apiBaseUrlWithSlash;

  // ============================================================================
  // AUTH ENDPOINTS
  // ============================================================================
  static const String login = '/api/auth/v1/signin/';
  static const String signup = '/api/auth/v1/signup/';
  static const String sendOtp = '/api/auth/v1/send-otp/';
  static const String verifyOTP = '/api/auth/v1/verify-otp/';
  static const String resetPassword = '/api/auth/v1/reset-password/';
  static const String addAddress = '/api/auth/v1/address/';
  static const String addresses = '/api/auth/v1/address/';
  static const String profile = '/api/auth/v1/profile/';

  // ============================================================================
  // ADMIN ENDPOINTS
  // ============================================================================
  static const String adminPhone = '/api/accounts/v1/admin/phone/';

  // ============================================================================
  // CATEGORY ENDPOINTS
  // ============================================================================
  static const String categories = 'api/products/v1/category/';
  static String categoryProducts(String categoryId) =>
      'api/products/v1/?category_id=$categoryId';

  // ============================================================================
  // PRODUCT ENDPOINTS
  // ============================================================================
  static String productVariant(String variantId) =>
      'api/products/v1/variants/$variantId/';

  // ============================================================================
  // ORDER ENDPOINTS
  // ============================================================================
  static const String orders = '/api/order/v1/orders/';
  static String orderDetails(String orderId) =>
      '/api/order/v1/orders/$orderId/';
  static String orderRating(String orderId) =>
      '/api/order/v1/$orderId/ratings/';
  static String orderRatingWithId(String orderId, int ratingId) =>
      '/api/order/v1/$orderId/ratings/$ratingId/';

  /// Get order lines by order ID using query parameter
  static String orderLinesByOrder(String orderId) =>
      '/api/order/v1/order-lines/?order=$orderId';

  // ============================================================================
  // CHECKOUT / PAYMENT ENDPOINTS
  // ============================================================================
  static String applyCoupon(int checkoutId) =>
      'api/order/v1/checkouts/$checkoutId/';
  static const String paymentInitiate = '/api/order/v1/checkout/';
  static const String paymentVerify = '/api/order/v1/payment/verify/';

  // ============================================================================
  // CART (CHECKOUT LINES) ENDPOINTS
  // ============================================================================
  static const String checkoutLines = '/api/order/v1/checkout-lines/';
  static String checkoutLineById(int lineId) =>
      '/api/order/v1/checkout-lines/$lineId/';

  // ============================================================================
  // WISHLIST ENDPOINTS
  // ============================================================================
  static const String wishlist = '/api/order/v1/wishlist/';
  static String wishlistById(String id) => '/api/order/v1/wishlist/$id/';

  // ============================================================================
  // DELIVERY ENDPOINTS
  // ============================================================================
  /// List deliveries by order ID
  static String deliveriesByOrder(int orderId) =>
      '/api/delivery/v1/deliveries/?order=$orderId';

  /// Get delivery details by delivery ID
  static String deliveryDetails(int deliveryId) =>
      '/api/delivery/v1/deliveries/$deliveryId/';
}

// Alias for backward compatibility
typedef Endpoints = ApiEndpoints;

/// Endpoints specific to the Home feature and initial data loading.
class HomeEndpoints {
  const HomeEndpoints._();

  static const String categories = '/api/products/v1/category/';
  static const String discountedVariants =
      '/api/products/v1/variants/discounts/';
  static const String products = '/api/products/v1/';
}
