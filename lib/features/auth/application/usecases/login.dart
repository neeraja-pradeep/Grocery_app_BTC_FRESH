// lib/features/auth/application/usecases/login.dart

/// Login use case
class LoginUseCase {
  Future<bool> execute(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    return email.isNotEmpty && password.isNotEmpty;
  }
}
