import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../data_sources/local/profile_local_ds.dart';
import '../data_sources/remote/profile_api.dart';

/// Result of fetching profile with cache information
class ProfileFetchResult {
  const ProfileFetchResult({
    required this.profile,
    required this.isStale,
    required this.fromCache,
  });

  final Profile profile;
  final bool isStale;
  final bool fromCache;
}

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({
    required ProfileApi remoteDs,
    required ProfileLocalDs localDs,
  }) : _remoteDs = remoteDs,
       _localDs = localDs;

  final ProfileApi _remoteDs;
  final ProfileLocalDs _localDs;

  /// Fetches profile with cache-first strategy:
  /// 1. Returns cached data immediately if available (even if stale)
  /// 2. Triggers background API refresh
  /// Returns ProfileFetchResult with cache metadata
  Future<ProfileFetchResult> fetchProfileWithCache() async {
    // Step 1: Try to get cached data first
    final cachedResult = await _localDs.getCachedProfile();

    if (cachedResult != null) {
      // Return cached data immediately
      return ProfileFetchResult(
        profile: cachedResult.profile.toDomain(),
        isStale: cachedResult.isStale,
        fromCache: true,
      );
    }

    // Step 2: No cache available, must fetch from API
    try {
      final response = await _remoteDs.fetchProfile();

      if (response.isNotModified || response.profile == null) {
        throw const FormatException('No profile data available.');
      }

      // Cache asynchronously (non-blocking)
      _localDs.cacheProfileAsync(response.profile!);

      return ProfileFetchResult(
        profile: response.profile!.toDomain(),
        isStale: false,
        fromCache: false,
      );
    } catch (error) {
      // API failed and no cache - rethrow error
      rethrow;
    }
  }

  /// Refreshes profile from API (background refresh)
  /// Returns fresh data or null if fails or data not modified
  Future<Profile?> refreshProfileFromApi() async {
    try {
      final response = await _remoteDs.fetchProfile();

      // 304 Not Modified or no data - nothing to update
      if (response.isNotModified || response.profile == null) {
        return null;
      }

      // Cache asynchronously (non-blocking)
      _localDs.cacheProfileAsync(response.profile!);

      return response.profile!.toDomain();
    } catch (error) {
      // Silently fail - cache remains unchanged
      return null;
    }
  }

  @override
  Future<Profile> fetchProfile() async {
    // Backward compatibility: behaves like fetchProfileWithCache
    // but returns only the profile
    final result = await fetchProfileWithCache();
    return result.profile;
  }

  @override
  Future<Profile> updateProfile({
    required String fullName,
    required String phoneNumber,
  }) async {
    final profileDto = await _remoteDs.updateProfile(
      fullName: fullName,
      phoneNumber: phoneNumber,
    );

    // Update cache asynchronously (non-blocking)
    _localDs.cacheProfileAsync(profileDto);

    return profileDto.toDomain();
  }

  @override
  Future<void> deleteAccount() async {
    await _remoteDs.deleteAccount();

    // Clear all cached profile data after account deletion
    await _localDs.clearAll();
  }

  @override
  Future<void> logout() async {
    // Clear all cached profile data on logout
    await _localDs.clearAll();
  }
}
