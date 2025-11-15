class HiveCacheKeys {
  const HiveCacheKeys._();

  static const String categoriesPayload = 'categories_payload';

  static String categoryProducts(String categoryId) =>
      'category_products_$categoryId';
}
