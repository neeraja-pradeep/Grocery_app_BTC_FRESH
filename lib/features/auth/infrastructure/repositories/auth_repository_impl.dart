// lib/features/auth/infrastructure/repositories/auth_repository_impl.dart

import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/remote/auth_api.dart';
import '../data_sources/local/auth_local_ds.dart';

/// Authentication repository implementation
class AuthRepositoryImpl implements AuthRepository {
  final AuthApi _authApi;
  final AuthLocalDataSource _localDataSource;

  AuthRepositoryImpl({
    required AuthApi authApi,
    required AuthLocalDataSource localDataSource,
  }) : _authApi = authApi,
       _localDataSource = localDataSource;

  @override
  Future<User> login(String email, String password) async {
    final response = await _authApi.login(email, password);
    final user = User.fromJson(response);
    await _localDataSource.saveToken(response['token']);
    return user;
  }

  @override
  Future<void> logout() async {
    await _authApi.logout();
    await _localDataSource.clearToken();
  }

  @override
  Future<User?> getCurrentUser() async {
    final token = await _localDataSource.getToken();
    if (token == null) return null;
    // TODO: Fetch user from API using token
    return null;
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _localDataSource.getToken();
    return token != null;
  }
}
