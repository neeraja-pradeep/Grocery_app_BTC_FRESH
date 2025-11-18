import '../entities/profile.dart';

abstract class ProfileRepository {
  /// Fetches the current user's profile from remote or cache.
  Future<Profile> fetchProfile();

  /// Updates the user's profile information.
  Future<Profile> updateProfile({
    required String fullName,
    required String mobileNumber,
    String? location,
  });

  /// Deletes the user's account permanently.
  Future<void> deleteAccount();

  /// Logs out the current user and clears cached data.
  Future<void> logout();
}
