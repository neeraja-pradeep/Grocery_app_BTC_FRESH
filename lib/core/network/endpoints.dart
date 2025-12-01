class ApiEndpoints {
  const ApiEndpoints._();

  static const String baseUrl = 'http://156.67.104.149:8080/';

  /// Categories list endpoint response uses REST pagination.
  static const String categories = 'api/products/category/';

  static String categoryProducts(String categoryId) =>
      'api/products/?category_id=$categoryId';

  /// Profile endpoint
  static const String profile = 'api/auth/profile/';
}

// Alias for backward compatibility
typedef Endpoints = ApiEndpoints;

/// Endpoints specific to the Home feature and initial data loading.
class HomeEndpoints {
  const HomeEndpoints._();

  // Path for fetching the list of product categories
  static const String categories = '/api/products/category/';

  // Path for fetching discounted product variants (used for Best Deals and Mega Offers)
  static const String discountedVariants = '/api/products/variants/discounts/';

  // Path for searching products (query parameter will be appended by the repository)
  static const String search = '/api/v1/products/search';

  // Path for searching products using the new API
  static const String products = '/api/products/';

  // Path for fetching the minimal profile summary needed for the header
  static const String profileHeader = '/api/v1/users/profile/summary';
}
