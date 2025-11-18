import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../data_sources/local/profile_local_ds.dart';
import '../data_sources/remote/profile_api.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl({
    required ProfileApi remoteDs,
    required ProfileLocalDs localDs,
  })  : _remoteDs = remoteDs,
        _localDs = localDs;

  final ProfileApi _remoteDs;
  final ProfileLocalDs _localDs;

  @override
  Future<Profile> fetchProfile() async {
    try {
      // Try to fetch from remote first
      final profileDto = await _remoteDs.fetchProfile();

      // Cache the fetched profile
      await _localDs.cacheProfile(profileDto);

      return profileDto.toDomain();
    } catch (error) {
      // If remote fails, try to return cached data
      final cachedDto = await _localDs.getCachedProfile();
      if (cachedDto != null) {
        return cachedDto.toDomain();
      }

      // If both fail, rethrow the error
      rethrow;
    }
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

    // Update the cache with new profile data
    await _localDs.cacheProfile(profileDto);

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
