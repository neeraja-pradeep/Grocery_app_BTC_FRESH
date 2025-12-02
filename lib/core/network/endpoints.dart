/// Centralized API endpoint configuration
///
/// This class organizes all API endpoints with documentation about:
/// - Endpoint purpose and response format
/// - Last-Modified / ETag support status for conditional requests
/// - Required parameters
/// - Pagination support
///
/// CONDITIONAL REQUEST SUPPORT:
/// =============================
/// Endpoints marked with ✅ support If-Modified-Since / If-None-Match headers:
/// - Returns 304 Not Modified when data unchanged (saves bandwidth)
/// - Returns 200 OK with Last-Modified / ETag headers when data changed
///
/// Endpoints marked with ❌ do NOT support conditional requests:
/// - Always returns 200 OK with fresh data
/// - No Last-Modified / ETag headers in response
class ApiEndpoints {
  const ApiEndpoints._();

  /// Base URL for all API requests
  static const String baseUrl = 'http://156.67.104.149:8080/';

  // ============================================================================
  // CATEGORY ENDPOINTS
  // ============================================================================

  /// Fetch all categories
  ///
  /// ✅ SUPPORTS CONDITIONAL REQUESTS (If-Modified-Since / If-None-Match)
  /// - Pagination: Supported (returns count, next, previous)
  /// - Response format: Paginated list of CategoryDto
  /// - Last-Modified header: Present when data changed
  /// - ETag header: Present for caching
  ///
  /// Usage:
  /// ```
  /// GET /api/products/category/
  /// Headers (optional):
  ///   If-Modified-Since: Wed, 21 Oct 2024 07:28:00 GMT
  ///   If-None-Match: "abc123"
  /// Response:
  ///   200 OK with categories + Last-Modified + ETag headers
  ///   OR
  ///   304 Not Modified (no response body)
  /// ```
  static const String categories = 'api/products/category/';

  /// Fetch products for a specific category
  ///
  /// ✅ SUPPORTS CONDITIONAL REQUESTS (If-Modified-Since / If-None-Match)
  /// - Pagination: Supported (returns count, next, previous)
  /// - Response format: Paginated list of ProductDto
  /// - Last-Modified header: Present when data changed
  /// - ETag header: Present for caching
  ///
  /// Parameters:
  /// - [categoryId]: The category ID to fetch products for
  ///
  /// Usage:
  /// ```
  /// GET /api/products/?category_id=5
  /// Headers (optional):
  ///   If-Modified-Since: Wed, 21 Oct 2024 07:28:00 GMT
  ///   If-None-Match: "def456"
  /// Response:
  ///   200 OK with products + Last-Modified + ETag headers
  ///   OR
  ///   304 Not Modified (no response body)
  /// ```
  static String categoryProducts(String categoryId) =>
      'api/products/?category_id=$categoryId';

  /// Profile endpoint
  static const String profile = 'api/auth/profile/';

  // ============================================================================
  // PRODUCT DETAIL ENDPOINTS
  // ============================================================================

  /// Fetch product variant details (images, price, availability)
  ///
  /// ✅ SUPPORTS CONDITIONAL REQUESTS (If-Modified-Since / If-None-Match)
  /// - Response format: Single ProductVariantDto
  /// - Last-Modified header: Present when data changed
  /// - ETag header: Present for caching
  /// - Contains: images, imageUrl, title, rating, price
  ///
  /// Parameters:
  /// - [variantId]: The variant ID (usually same as product ID for details)
  ///
  /// Usage:
  /// ```
  /// GET /api/products/variants/{variantId}/
  /// Headers (optional):
  ///   If-Modified-Since: Wed, 21 Oct 2024 07:28:00 GMT
  ///   If-None-Match: "ghi789"
  /// Response:
  ///   200 OK with variant data + Last-Modified + ETag headers
  ///   OR
  ///   304 Not Modified (no response body)
  /// ```
  static String productVariant(String variantId) =>
      'api/products/variants/$variantId/';

  /// Fetch product base data (description, media, rating, reviews count)
  ///
  /// ❌ DOES NOT SUPPORT CONDITIONAL REQUESTS
  /// - Always returns 200 OK with fresh data
  /// - No If-Modified-Since support in current API implementation
  /// - Response format: Single ProductBaseDto
  /// - Contains: description, media list, rating, reviews count
  ///
  /// Parameters:
  /// - [productId]: The product ID
  ///
  /// Usage:
  /// ```
  /// GET /api/products/{productId}/
  /// Response:
  ///   200 OK with product data (always fresh, no 304 support)
  /// ```
  static String productBase(String productId) => 'api/products/$productId/';

  /// Fetch product reviews
  ///
  /// ❌ DOES NOT SUPPORT CONDITIONAL REQUESTS
  /// - Always returns 200 OK with fresh data
  /// - Response format: List of ProductVariantReviewDto
  ///
  /// Parameters:
  /// - [productId]: The product ID
  static String productReviews(String productId) =>
      'api/products/$productId/reviews';

  // ============================================================================
  // WISHLIST ENDPOINTS
  // ============================================================================

  /// Check if product is in user's wishlist
  ///
  /// ❌ DOES NOT SUPPORT CONDITIONAL REQUESTS
  /// - Always returns 200 OK with fresh data
  /// - Response format: {inWishlist: bool}
  ///
  /// Parameters:
  /// - [productId]: The product ID to check
  static String isInWishlist(String productId) => 'wishlist/check/$productId';

  /// Add product to wishlist
  ///
  /// ❌ POST REQUEST (not applicable for conditional caching)
  /// - Request body: {productId: string}
  /// - Response: Success confirmation
  static const String addToWishlist = 'wishlist';

  /// Remove product from wishlist
  ///
  /// ❌ POST REQUEST (not applicable for conditional caching)
  /// - Request body: {productId: string}
  /// - Response: Success confirmation
  static const String removeFromWishlist = 'wishlist/remove';

  // ============================================================================
  // CONDITIONAL REQUEST IMPLEMENTATION GUIDE
  // ============================================================================
  //
  // For endpoints marked with ✅:
  //
  // 1. Store metadata from previous response:
  //    - lastModified = response.headers['Last-Modified']
  //    - eTag = response.headers['ETag']
  //
  // 2. On next request, include conditional headers:
  //    - If-Modified-Since: lastModified
  //    - If-None-Match: eTag
  //
  // 3. Server responds:
  //    - 304 Not Modified → Data unchanged, use cached data
  //    - 200 OK → Data changed, use fresh data + extract new headers
  //
  // See CacheHeadersHelper for reusable utility functions.

  // ============================================================================
  // ORDER / PAYMENT ENDPOINTS
  // ============================================================================

  /// Apply coupon to checkout
  ///
  /// ❌ PATCH REQUEST (not applicable for conditional caching)
  /// - Request body: {"coupon": coupon_id}
  /// - Response: Updated checkout with coupon applied
  ///
  /// Parameters:
  /// - [checkoutId]: The checkout ID to apply coupon to
  static String applyCoupon(int checkoutId) =>
      'api/order/checkouts/$checkoutId/';

  /// Create order and get Razorpay order details for payment
  ///
  /// ❌ POST REQUEST (not applicable for conditional caching)
  /// - Request body: Order details (address_id, items, etc.)
  /// - Response: Order details with razorpay_order_id for payment
  static const String orderCheckout = 'api/order/checkout/';

  /// Verify Razorpay payment after successful payment
  ///
  /// ❌ POST REQUEST (not applicable for conditional caching)
  /// - Request body: {razorpay_payment_id, razorpay_order_id, razorpay_signature}
  /// - Response: Payment verification status
  static const String paymentVerify = 'api/order/payment/verify/';
}
