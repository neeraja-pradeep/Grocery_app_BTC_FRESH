import 'package:grocery_app/core/storage/hive/keys.dart';
import 'package:hive/hive.dart';

import 'category_product_cache_dto.dart';

class CategoryProductLocalDataSource {
  CategoryProductLocalDataSource(this._box);

  final Box<dynamic> _box;

  CategoryProductCacheDto? read(String categoryId) {
    final key = HiveKeys.categoryProducts(categoryId);
    final raw = _box.get(key);
    if (raw == null) return null;

    if (raw is Map<String, dynamic>) {
      return CategoryProductCacheDto.fromJson(raw);
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return CategoryProductCacheDto.fromJson(map);
    }
    return null;
  }

  Future<void> save(CategoryProductCacheDto dto) async {
    final key = HiveKeys.categoryProducts(dto.categoryId);
    await _box.put(key, dto.toJson());
  }

  Future<void> updateLastSyncedAt(String categoryId, DateTime timestamp) async {
    final key = HiveKeys.categoryProducts(categoryId);
    final raw = _box.get(key);
    if (raw == null) return;

    if (raw is! Map) return;

    final map = Map<String, dynamic>.from(raw);

    map['lastSyncedAt'] = timestamp.toIso8601String();
    await _box.put(key, map);
  }

  Future<void> clear(String categoryId) async {
    final key = HiveKeys.categoryProducts(categoryId);
    await _box.delete(key);
  }
}
