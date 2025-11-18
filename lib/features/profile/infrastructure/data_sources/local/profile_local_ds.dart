import 'package:hive_flutter/hive_flutter.dart';

import '../../models/profile_dto.dart';
import 'profile_cache_dto.dart';

class ProfileLocalDs {
  const ProfileLocalDs({required Box<dynamic> box}) : _box = box;

  final Box<dynamic> _box;

  static const String _kProfileKey = 'cached_profile';

  /// Retrieves the cached profile if available and not expired.
  Future<ProfileDto?> getCachedProfile() async {
    final rawData = _box.get(_kProfileKey);
    if (rawData == null) return null;

    try {
      final cacheDto = ProfileCacheDto.fromJson(
        Map<String, dynamic>.from(rawData as Map),
      );

      // Cache validity: 24 hours
      final age = DateTime.now().difference(cacheDto.cachedAt);
      if (age.inHours > 24) {
        await _box.delete(_kProfileKey);
        return null;
      }

      return cacheDto.toDto();
    } catch (_) {
      await _box.delete(_kProfileKey);
      return null;
    }
  }

  /// Saves the profile to local cache.
  Future<void> cacheProfile(ProfileDto profile) async {
    final cacheDto = ProfileCacheDto.fromDto(profile);
    await _box.put(_kProfileKey, cacheDto.toJson());
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
