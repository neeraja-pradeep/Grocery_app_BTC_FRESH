/// Centralized API endpoint configuration
class ApiEndpoints {
  const ApiEndpoints._();

  /// Base URL for all API requests
  static const String baseUrl = 'http://156.67.104.149:8080/';

  // ============================================================================
  // AUTH ENDPOINTS
  // ============================================================================
  static const String login = '/api/auth/signin/';
  static const String signup = '/api/auth/signup/';
  static const String sendOtp = '/api/auth/send-otp/';
  static const String verifyOTP = '/api/auth/verify-otp/';
  static const String resetPassword = '/api/auth/reset-password/';
  static const String addAddress = '/api/auth/address/';
  static const String profile = 'api/auth/profile/';

  // ============================================================================
  // CATEGORY ENDPOINTS
  // ============================================================================
  static const String categories = 'api/products/category/';

  static String categoryProducts(String categoryId) =>
      'api/products/?category_id=$categoryId';

  // ============================================================================
  // PRODUCT DETAIL ENDPOINTS
  // ============================================================================
  static String productVariant(String variantId) =>
      'api/products/variants/$variantId/';

  static String productBase(String productId) => 'api/products/$productId/';

  static String productReviews(String productId) =>
      'api/products/$productId/reviews';

  // ============================================================================
  // WISHLIST ENDPOINTS
  // ============================================================================
  static String isInWishlist(String productId) => 'wishlist/check/$productId';
  static const String addToWishlist = 'wishlist';
  static const String removeFromWishlist = 'wishlist/remove';

  // ============================================================================
  // ORDER / PAYMENT ENDPOINTS
  // ============================================================================
  static String applyCoupon(int checkoutId) =>
      'api/order/checkouts/$checkoutId/';
  static const String paymentInitiate = 'api/order/payment/initiate/';
  static const String paymentVerify = 'api/order/payment/verify/';

  // ============================================================================
  // ORDERS ENDPOINTS
  // ============================================================================
  static const String orders = '/api/order/orders/';
  static const String activeOrders = '/api/order/orders/?status=active';
  static const String pendingOrders = '/api/order/orders/?status=pending';
  static String orderDetails(String orderId) => '/api/order/orders/$orderId/';

  // ============================================================================
  // CART (CHECKOUT LINES) ENDPOINTS
  // ============================================================================
  static const String checkoutLines = '/api/order/checkout-lines/';
  static String checkoutLineById(int lineId) =>
      '/api/order/checkout-lines/$lineId/';

  // ============================================================================
  // CHECKOUT ENDPOINTS
  // ============================================================================
  static const String checkouts = '/api/order/checkouts/';

  // ============================================================================
  // ADDRESS ENDPOINTS
  // ============================================================================
  static const String addresses = '/api/auth/address/';
  static const String selectedAddress = '/api/auth/address/?selected=true';
}

// Alias for backward compatibility
typedef Endpoints = ApiEndpoints;

/// Endpoints specific to the Home feature and initial data loading.
class HomeEndpoints {
  const HomeEndpoints._();

  static const String categories = '/api/products/category/';
  static const String discountedVariants = '/api/products/variants/discounts/';
  static const String search = '/api/v1/products/search';
  static const String products = '/api/products/';
  static const String profileHeader = '/api/v1/users/profile/summary';
}
