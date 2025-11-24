class ApiEndpoints {
  const ApiEndpoints._();

  static const String baseUrl = 'http://156.67.104.149:8080/';

  /// Categories list endpoint response uses REST pagination.
  static const String categories = 'api/products/category/';

  static String categoryProducts(String categoryId) =>
      'api/products/?category_id=$categoryId';
  static const String login = '/api/auth/signin/';
  static const String signup = '/api/auth/signup/';
  static const String sendOtp = '/api/auth/send-otp/';
  static const String verifyOTP = '/api/auth/verify-otp/';

  static const String addAddress = '/api/auth/address/';
}
