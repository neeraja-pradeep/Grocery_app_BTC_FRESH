// lib/features/auth/application/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../states/auth_state.dart';

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState.initial());

  Future<void> login(String email, String password) async {
    state = const AuthState.loading();
    // TODO: Implement login logic
    await Future.delayed(const Duration(seconds: 1));
    state = const AuthState.authenticated();
  }

  void logout() {
    state = const AuthState.unauthenticated();
  }
}
