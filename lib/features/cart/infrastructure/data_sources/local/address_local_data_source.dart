import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../../../../core/storage/cache_config.dart';
import 'address_cache_dto.dart';

/// Local data source for address cache metadata
/// Uses single global Hive box with namespaced keys (following CacheConfig pattern)
abstract class AddressLocalDataSource {
  /// Get cached address list metadata (Last-Modified, ETag)
  Future<AddressCacheDto?> getCachedAddressList();

  /// Cache address list metadata
  Future<void> cacheAddressListWithMetadata(AddressCacheDto cacheDto);

  /// Clear all address cache
  Future<void> clearCache();
}

class AddressLocalDataSourceImpl implements AddressLocalDataSource {
  /// Key for address list cache in global Hive box
  /// Format: 'address:list_meta'
  static const String _addressListKey = 'address:list_meta';

  /// Get global Hive box (single box for all features)
  Future<Box> get _box async {
    if (!Hive.isBoxOpen(CacheConfig.hiveBoxName)) {
      return await Hive.openBox(CacheConfig.hiveBoxName);
    }
    return Hive.box(CacheConfig.hiveBoxName);
  }

  @override
  Future<AddressCacheDto?> getCachedAddressList() async {
    try {
      final box = await _box;
      final json = box.get(_addressListKey) as Map<dynamic, dynamic>?;

      if (json == null) return null;

      return AddressCacheDto.fromJson(Map<String, dynamic>.from(json));
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheAddressListWithMetadata(AddressCacheDto cacheDto) async {
    try {
      final box = await _box;
      await box.put(_addressListKey, cacheDto.toJson());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      final box = await _box;
      await box.delete(_addressListKey);
    } catch (e) {
      rethrow;
    }
  }
}
