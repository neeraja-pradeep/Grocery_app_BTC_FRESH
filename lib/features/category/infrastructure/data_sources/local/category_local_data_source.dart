import 'category_cache_dto.dart';

class CategoryLocalDataSource {
  CategoryLocalDataSource();

  /// Returns null (no caching)
  CategoryCacheDto? read() {
    return null;
  }

  /// No-op (no caching)
  Future<void> save(CategoryCacheDto dto) async {
    // Hive caching removed
  }

  /// No-op (no caching)
  Future<void> updateLastSyncedAt(DateTime timestamp) async {
    // Hive caching removed
  }

  /// No-op (no caching)
  Future<void> clear() async {
    // Hive caching removed
  }
}
