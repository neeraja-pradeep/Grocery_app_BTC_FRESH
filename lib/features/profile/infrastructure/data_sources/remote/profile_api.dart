import '../../../../../core/network/api_client.dart';

import '../../models/profile_dto.dart';

/// Response wrapper for profile fetch with cache headers
class ProfileFetchResponse {
  const ProfileFetchResponse({
    required this.profile,
    this.lastModified,
    this.isNotModified = false,
  });

  /// Creates a 304 Not Modified response
  factory ProfileFetchResponse.notModified() =>
      const ProfileFetchResponse(profile: null, isNotModified: true);

  final ProfileDto? profile;
  final String? lastModified;
  final bool isNotModified;
}

class ProfileApi {
  const ProfileApi({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// Fetches the current user's profile from the backend.
  ///
  /// Optionally supports conditional requests with [ifModifiedSince] header.
  /// Returns the Last-Modified header from response for caching.
  Future<ProfileFetchResponse> fetchProfile({String? ifModifiedSince}) async {
    // Add conditional header if provided (for cache validation)
    final headers = <String, String>{};
    if (ifModifiedSince != null) {
      headers['If-Modified-Since'] = ifModifiedSince;
    }

    final response = await _client.get<Map<String, dynamic>>(
      'api/auth/v1/profile/',
      headers: headers.isEmpty ? null : headers,
    );

    // Handle 304 Not Modified - data hasn't changed
    if (response.statusCode == 304) {
      return ProfileFetchResponse.notModified();
    }

    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty profile response.');
    }

    // Extract Last-Modified header for future conditional requests
    final lastModified =
        response.headers.value('last-modified') ??
        response.headers.value('Last-Modified');

    return ProfileFetchResponse(
      profile: ProfileDto.fromJson(data),
      lastModified: lastModified,
    );
  }

  /// Updates the user's profile information.
  Future<ProfileDto> updateProfile({
    required String fullName,
    required String phoneNumber,
    String? email,
  }) async {
    // Split fullName into first_name and last_name
    final nameParts = ProfileDto.splitFullName(fullName);

    final response = await _client.patch<Map<String, dynamic>>(
      'api/auth/v1/profile/',
      data: <String, dynamic>{
        'first_name': nameParts['first_name'],
        'last_name': nameParts['last_name'],
        'phone_number': phoneNumber,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );

    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty update profile response.');
    }

    return ProfileDto.fromJson(data);
  }

  /// Deletes the user's account.
  Future<void> deleteAccount() async {
    await _client.post<void>('api/auth/v1/delete-account/');
  }
}
