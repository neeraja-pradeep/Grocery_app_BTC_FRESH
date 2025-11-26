// features/home/infrastructure/data_sources/remote/endpoints.dart

class Endpoints {
  // Base URL for the entire application API
  static const String baseUrl = 'http://156.67.104.149:8080';
}

/// Endpoints specific to the Home feature and initial data loading.
class HomeEndpoints {
  // Path for fetching the list of product categories (NEW: /api/products/category/)
  static const String categories = '/api/products/category/';

  // Path for fetching discounted product variants (used for Best Deals and Mega Offers)
  static const String discountedVariants = '/api/products/variants/discounts/';

  // Path for searching products (query parameter will be appended by the repository)
  static const String search = '/api/v1/products/search';

  // Path for searching products using the new API
  static const String products = '/api/products/';

  // Path for fetching the minimal profile summary needed for the header (e.g., /users/profile/summary)
  static const String profileHeader = '/api/v1/users/profile/summary';
}
