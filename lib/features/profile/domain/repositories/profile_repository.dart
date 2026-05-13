import '../entities/profile.dart';

/// Result of a cache-first profile fetch with staleness metadata.
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

abstract class ProfileRepository {
  /// Fetches profile with a cache-first strategy; includes cache metadata.
  Future<ProfileFetchResult> fetchProfileWithCache();

  /// Fetches fresh profile from API; returns null on 304 or transient failure.
  Future<Profile?> refreshProfileFromApi();

  /// Fetches the current user's profile from remote or cache.
  Future<Profile> fetchProfile();

  /// Updates the user's profile information.
  Future<Profile> updateProfile({
    required String fullName,
    required String phoneNumber,
  });

  /// Deletes the user's account permanently.
  Future<void> deleteAccount();

  /// Logs out the current user and clears cached data.
  Future<void> logout();
}
