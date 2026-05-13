import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../../../../core/storage/cache_config.dart';
import '../../models/profile_dto.dart';
import 'profile_cache_dto.dart';

/// Wrapper class to return cached profile with staleness information
class CachedProfileResult {
  const CachedProfileResult({required this.profile, required this.isStale});

  final ProfileDto profile;
  final bool isStale;
}

class ProfileLocalDs {
  const ProfileLocalDs({required Box<dynamic> box}) : _box = box;

  final Box<dynamic> _box;

  static const String _kProfileKey = 'cached_profile';

  /// Retrieves the cached profile if available (returns even if stale).
  /// Never deletes cache - always returns data with staleness flag.
  Future<CachedProfileResult?> getCachedProfile() async {
    final rawData = _box.get(_kProfileKey);
    if (rawData == null) return null;

    try {
      final cacheDto = ProfileCacheDto.fromJson(
        Map<String, dynamic>.from(rawData as Map),
      );

      // Check cache age
      final age = DateTime.now().difference(cacheDto.cachedAt);
      final isStale = age > CacheConfig.staleCacheThreshold;

      // Always return data, even if stale
      return CachedProfileResult(profile: cacheDto.toDto(), isStale: isStale);
    } catch (e, st) {
      debugPrint('[ProfileLocalDs] corrupted cache entry, deleting: $e\n$st');
      await _box.delete(_kProfileKey);
      return null;
    }
  }

  /// Saves the profile to local cache (async, non-blocking).
  /// This method is fire-and-forget to avoid blocking UI updates.
  void cacheProfileAsync(ProfileDto profile) {
    // Fire-and-forget: don't await
    _saveCacheInternal(profile);
  }

  Future<void> _saveCacheInternal(ProfileDto profile) async {
    try {
      final cacheDto = ProfileCacheDto.fromDto(profile);
      await _box.put(_kProfileKey, cacheDto.toJson());
    } catch (e, st) {
      debugPrint('[ProfileLocalDs] cache write failed: $e\n$st');
    }
  }

  /// Clears the cached profile data.
  Future<void> clearCache() async {
    await _box.delete(_kProfileKey);
  }

  /// Clears all data in the profile box (used on logout).
  Future<void> clearAll() async {
    await _box.clear();
  }
}
