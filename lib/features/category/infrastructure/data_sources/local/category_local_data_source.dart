import 'package:grocery_app/core/storage/hive/keys.dart';
import 'package:hive/hive.dart';

import 'category_cache_dto.dart';

class CategoryLocalDataSource {
  CategoryLocalDataSource(this._box);

  final Box<dynamic> _box;

  CategoryCacheDto? read() {
    final raw = _box.get(HiveCacheKeys.categoriesPayload);
    if (raw == null) return null;

    if (raw is Map<String, dynamic>) {
      return CategoryCacheDto.fromJson(raw);
    }

    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      return CategoryCacheDto.fromJson(map);
    }

    return null;
  }

  Future<void> save(CategoryCacheDto dto) async {
    await _box.put(HiveCacheKeys.categoriesPayload, dto.toJson());
  }

  Future<void> updateLastSyncedAt(DateTime timestamp) async {
    final raw = _box.get(HiveCacheKeys.categoriesPayload);
    if (raw == null) return;

    if (raw is! Map) return;

    final map = Map<String, dynamic>.from(raw);

    map['lastSyncedAt'] = timestamp.toIso8601String();
    await _box.put(HiveCacheKeys.categoriesPayload, map);
  }

  Future<void> clear() async {
    await _box.delete(HiveCacheKeys.categoriesPayload);
  }
}
