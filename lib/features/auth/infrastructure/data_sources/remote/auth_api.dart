// lib/features/auth/infrastructure/data_sources/remote/auth_api.dart

/// Remote authentication API
class AuthApi {
  Future<Map<String, dynamic>> login(String email, String password) async {
    // TODO: Implement API login
    await Future.delayed(const Duration(seconds: 1));
    return {
      'id': '1',
      'email': email,
      'name': 'User Name',
      'token': 'mock_token',
    };
  }

  Future<void> logout() async {
    // TODO: Implement API logout
  }
}
