class ApiEndpoints {
  const ApiEndpoints._();

  static const String baseUrl = 'http://156.67.104.149:8080/';

  /// Categories list endpoint response uses REST pagination.
  static const String categories = 'api/products/category/';

  static String categoryProducts(String categoryId) =>
      'api/products/?category_id=$categoryId';
}
