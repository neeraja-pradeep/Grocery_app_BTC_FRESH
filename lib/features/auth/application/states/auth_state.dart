// lib/features/auth/application/states/auth_state.dart

/// Authentication state
sealed class AuthState {
  const AuthState();

  const factory AuthState.initial() = AuthInitial;
  const factory AuthState.loading() = AuthLoading;
  const factory AuthState.authenticated() = AuthAuthenticated;
  const factory AuthState.unauthenticated() = AuthUnauthenticated;
  const factory AuthState.error(String message) = AuthError;
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
