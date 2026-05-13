import 'package:flutter/foundation.dart';

import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../data_sources/local/profile_local_ds.dart';
import '../data_sources/remote/profile_api.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({
    required ProfileApi remoteDs,
    required ProfileLocalDs localDs,
  }) : _remoteDs = remoteDs,
       _localDs = localDs;

  final ProfileApi _remoteDs;
  final ProfileLocalDs _localDs;

  @override
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
    } catch (error, st) {
      debugPrint('[ProfileRepositoryImpl] cold-start fetch failed: $error\n$st');
      rethrow;
    }
  }

  @override
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
