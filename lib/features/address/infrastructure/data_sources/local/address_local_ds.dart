import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../models/address_dto.dart';
import 'address_cache_dto.dart';

/// Wrapper class to return cached addresses with staleness information
class CachedAddressListResult {
  const CachedAddressListResult({
    required this.addresses,
    required this.isStale,
  });

  final List<AddressDto> addresses;
  final bool isStale;
}

class AddressLocalDs {
  const AddressLocalDs({required Box<dynamic> box}) : _box = box;

  final Box<dynamic> _box;

  static const String _kAddressListKey = 'cached_addresses';
  static const int _kCacheValidityHours = 24;

  /// Retrieves the cached address list if available (returns even if stale).
  /// Never deletes cache - always returns data with staleness flag.
  Future<CachedAddressListResult?> getCachedAddresses() async {
    final rawData = _box.get(_kAddressListKey);
    if (rawData == null) return null;

    try {
      final cacheMap = Map<String, dynamic>.from(rawData as Map);
      final addressListJson = cacheMap['addresses'] as List;
      final cachedAt = DateTime.parse(cacheMap['cachedAt'] as String);

      final addressDtos = addressListJson
          .map(
            (json) => AddressCacheDto.fromJson(
              Map<String, dynamic>.from(json as Map),
            ),
          )
          .map((cacheDto) => cacheDto.toDto())
          .toList();

      // Check cache age
      final age = DateTime.now().difference(cachedAt);
      final isStale = age.inHours > _kCacheValidityHours;

      // Always return data, even if stale
      return CachedAddressListResult(addresses: addressDtos, isStale: isStale);
    } catch (_) {
      // If data is corrupted, return null but don't delete
      return null;
    }
  }

  /// Saves the address list to local cache (async, non-blocking).
  /// This method is fire-and-forget to avoid blocking UI updates.
  void cacheAddressListAsync(List<AddressDto> addresses) {
    _saveCacheInternal(addresses);
  }

  Future<void> _saveCacheInternal(List<AddressDto> addresses) async {
    try {
      final cacheDtos = addresses
          .map(AddressCacheDto.fromDto)
          .map((dto) => dto.toJson())
          .toList();

      final cacheData = <String, dynamic>{
        'addresses': cacheDtos,
        'cachedAt': DateTime.now().toIso8601String(),
      };

      await _box.put(_kAddressListKey, cacheData);
    } catch (_) {
      // Silently fail - cache is not critical
    }
  }

  /// Clears the cached address list.
  Future<void> clearCache() async {
    await _box.delete(_kAddressListKey);
  }

  /// Clears all data in the address box (used on logout).
  Future<void> clearAll() async {
    await _box.clear();
  }
}
