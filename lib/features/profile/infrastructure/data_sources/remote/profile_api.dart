import 'package:grocery_app/core/network/api_client.dart';

import '../../models/profile_dto.dart';

class ProfileApi {
  const ProfileApi({required ApiClient client}) : _client = client;

  final ApiClient _client;

  /// Fetches the current user's profile from the backend.
  Future<ProfileDto> fetchProfile() async {
    final response = await _client.get<Map<String, dynamic>>(
      'api/auth/profile/',
      headers: {
        'dev': '2',
        'If-Modified-Since': 'Sun, 26 Oct 2025 09:51:00 GMT',
      },
    );

    final data = response.data;
    if (data == null) {
      throw const FormatException('Empty profile response.');
    }

    return ProfileDto.fromJson(data);
  }

  /// Updates the user's profile information.
  Future<ProfileDto> updateProfile({
    required String fullName,
    required String mobileNumber,
    String? location,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      'api/auth/profile/',
      data: <String, dynamic>{
        'full_name': fullName,
        'mobile_number': mobileNumber,
        if (location != null) 'location': location,
      },
      headers: {
        'dev': '2',
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
    await _client.post<void>(
      'api/auth/delete-account/',
      headers: {
        'dev': '2',
      },
    );
  }
}
