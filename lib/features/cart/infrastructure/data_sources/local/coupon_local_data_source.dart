import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../../../../core/storage/cache_config.dart';
import 'coupon_cache_dto.dart';

/// Local data source for coupon cache metadata
/// Uses single global Hive box with namespaced keys (following CacheConfig pattern)
abstract class CouponLocalDataSource {
  /// Get cached coupon list metadata (Last-Modified, ETag)
  Future<CouponCacheDto?> getCachedCouponList();

  /// Cache coupon list metadata
  Future<void> cacheCouponListWithMetadata(CouponCacheDto cacheDto);

  /// Clear all coupon cache
  Future<void> clearCache();
}

class CouponLocalDataSourceImpl implements CouponLocalDataSource {
  /// Key for coupon list cache in global Hive box
  /// Format: 'coupon:list_meta'
  static const String _couponListKey = 'coupon:list_meta';

  /// Get global Hive box (single box for all features)
  Future<Box> get _box async {
    if (!Hive.isBoxOpen(CacheConfig.hiveBoxName)) {
      return await Hive.openBox(CacheConfig.hiveBoxName);
    }
    return Hive.box(CacheConfig.hiveBoxName);
  }

  @override
  Future<CouponCacheDto?> getCachedCouponList() async {
    try {
      final box = await _box;
      final json = box.get(_couponListKey) as Map<dynamic, dynamic>?;

      if (json == null) return null;

      return CouponCacheDto.fromJson(Map<String, dynamic>.from(json));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheCouponListWithMetadata(CouponCacheDto cacheDto) async {
    try {
      final box = await _box;
      await box.put(_couponListKey, cacheDto.toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = await _box;
      await box.delete(_couponListKey);
    } catch (e) {
      rethrow;
    }
  }
}
