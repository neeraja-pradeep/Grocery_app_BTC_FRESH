class HiveKeys {
  const HiveKeys._();

  static const String categoriesPayload = 'categories_payload';

  static String categoryProducts(String categoryId) =>
      'category_products_$categoryId';
  static const userbox = 'user_box';
  static const addressBox = 'address_box';
}
