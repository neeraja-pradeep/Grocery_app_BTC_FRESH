// lib/features/auth/domain/repositories/auth_repository.dart

import '../entities/user.dart';

/// Authentication repository interface
abstract class AuthRepository {
  Future<User> login(String email, String password);
  Future<void> logout();
  Future<User?> getCurrentUser();
  Future<bool> isLoggedIn();
}
