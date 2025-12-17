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
