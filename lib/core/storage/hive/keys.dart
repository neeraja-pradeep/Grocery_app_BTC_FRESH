class HiveKeys {
  const HiveKeys._();

  // Auth keys
  static const userbox = 'user_box';
  static const addressBox = 'address_box';

  // Category cache keys
  static const String categoriesPayload = 'categories_payload';
  static String categoryProducts(String categoryId) =>
      'category_products_$categoryId';

  // Home screen cache keys
  static const String homeCategories = 'home_categories';
  static const String homeDiscounts = 'home_discounts_';
  static const String homeBestDeals = 'home_best_deals';
  static const String homeAdvertisement = 'home_ad';
  static const String userSelectedAddress = 'user_selected_address';
}
