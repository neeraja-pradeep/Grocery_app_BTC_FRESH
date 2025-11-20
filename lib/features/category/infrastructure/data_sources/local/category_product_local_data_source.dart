import 'category_product_cache_dto.dart';

class CategoryProductLocalDataSource {
  CategoryProductLocalDataSource();

  /// Returns null (no caching)
  CategoryProductCacheDto? read(String categoryId) {
    return null;
  }

  /// No-op (no caching)
  Future<void> save(CategoryProductCacheDto dto) async {
    // Hive caching removed
  }

  /// No-op (no caching)
  Future<void> updateLastSyncedAt(String categoryId, DateTime timestamp) async {
    // Hive caching removed
  }

  /// No-op (no caching)
  Future<void> clear(String categoryId) async {
    // Hive caching removed
  }
}
